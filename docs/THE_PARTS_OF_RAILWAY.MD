# The Parts of Railway
Before we start, let me remind you of something I mentioned in the "[Why do this](https://github.com/FestaLab/railway/blob/main/docs/WHY_DO_THIS.MD)" guide: We are not trying to recreate Heroku. We are only trying to get our own Rails app to production. This means that we need a much smaller subset of features than what Heroku offers.

To make Railway's infrastructure easier to understand for those that have never run their own servers before, I'm going compare each part of it to a part of Heroku that you are already familiar with. It looks more or less like the table below: 

| Component        | Heroku           | AWS                           |
| ---------------- |------------------|-------------------------------|
| Linux            | Stack & Buildpack| Amazon Machine Images         |
| Web Server       | Web Dynos        | EC2 with Puma service         |
| Worker Server    | Worker Dynos     | EC2 with Sidekiq service      |
| Database         | Heroku Postgres  | RDS with Postgres Engine      |
| Redis            | Heroku Redis     | Elasticache with Redis Engine |
| Logs             | LogPlex          | Cloudwatch Logs/Insights      |
| Metrics          | Dashboard        | Cloudwatch Metrics/Dashboards |
| Load Balancer    | Heroku Router    | ELB and Target Groups         |
| Environment Vars | Config vars      | `.rbenv-vars` file            |

## Linux
It should come as no surprise to you that both Heroku and Railway use Ubuntu in their servers. However you can't just choose the latest LTS and call it a day. Besides requiring a specific version of Ruby installed, most Rails apps also expect various other packages to be available, like node, yarn and ImageMagick. To solve that problem both Heroku and Railway create their own Ubuntu image.

#### Heroku: Stacks
Heroku is very good at making things "just work", but if you have been on it for a while you have probably come into contact with [Heroku Stacks](https://devcenter.heroku.com/articles/stack) and [Heroku Buildpacks](https://devcenter.heroku.com/articles/buildpacks). The company calls stacks "an operating system image that is curated and maintained by Heroku". That sounds nice, but if we are going to deploy our apps on AWS it helps understanding what is special about these images.

While I'm certain Heroku's engineers do a lot of stuff I'm not aware, the gist of it is that they take an Ubuntu LTS release, [install packages they believe are useful to most apps](https://devcenter.heroku.com/articles/stack-packages) (Rails or not), harden it through various means (disabling unnecessary services, limiting what users can ssh, etc.), and configure it to work with other components of their infrastructure, like Logplex.

However, those images do not have any language specific packages installed. Meaning: they don't have Ruby installed on them.

#### Railway: Amazon Images
When creating a new EC2 instance on Amazon, the first step is choosing the Amazon Image (AMI) that you wish to use. If you take a look at it you will see images for Red Hat, CentOS, Ubuntu, Windows and more. If you investigate a bit further you will see that instead of using Amazon's pre built AMIs, you can use your own AMIs.

Railway takes advantage of that to create something similar to Heroku Stacks. Every Railway project has its own "operating system images that are curated and maintained by Railway". To create those images Railway has a special Ansible playbook called `ami.yml`. You can make changes to it if your app needs any special package, but it should already have everything most Rails apps will need.

When you execute this playbook during the [First run guide](https://github.com/FestaLab/railway/blob/main/docs/FIRST_RUN.MD), Railway will do the following:

1. Create an EC2 instance using the latest Ubuntu LTS;
2. Create a user for Ansible to use;
3. Create a user for your app to use;
4. Add extra repositories for `node`, `yarn` and `postgres`;
5. Fully upgrade he system;
6. Install cron;
7. Configure the firewall;
8. Disable passwords logins and limit what users can ssh;
9. Install `collectd` to collect metrics like CPU and memory usage;
10. Remove/disable unnecessary services;
11. Install a collection of build tools and dev libs;
12. Install `python`, which Ansible will need in some playbooks;
13. Install `node` and `yarn`;
14. Install `postgres` client (needed for the `pg` gem);
15. Install `chrome` (for browser automation);
16. Install `ffmpeg`, `poppler`, `image_magick` and `libvips` (for Active Storage);
17. Install `ruby` with `jemalloc`;
18. Download a copy of your app;
19. Install rails;
20. Run `bundle install` and `yarn install`;
21. Shutdown the EC2 instance;
22. Create a timestamped AMI;
23. Destroy the instance;

The entire process takes a **very long** time, but after you run it to generate the first AMI, you will only need to run it again it you decide you need an extra package that your current AMI does not have.

Steps 18, 19 20 might look a little they shouldn't be here, but there's a reason for that: Next time Railway creates a new EC2 instance, its `bundle install` and `yarn install` step will be much faster since they will only need to install new/updated packages. 

#### An important difference: Heroku's deploys vs Railway's deploys and how they scale 
If you compare Heroku's Stack with Railway's AMI at this point, Railways' Ubuntu image is more complete: it already has Ruby, Rails and all other Gems installed. The reason for that is a difference between what each one is optimizing for.

When you deploy on Heroku, you are not actually downloading a new version of your code to your dynos. Instead, Heroku uses a process called "slug compilation", that does the following:
1. Take the stack image that the app is configured for (Heroku-18 or Heroku-20);
2. Install the buildpack for the language and version that the app uses, as well as all other buildpacks that the user has added;
3. Install the packages in the AptFile;
4. Clone the app from the repo;   
5. Run `bundle install` to install the gems;
6. Run `yarn install` to install the packages;
7. Run `assets:precompile`;
8. Generate a new slug (image) of the result;
9. Run `db:migrate`   
10. Create new dynos using said slug;
11. Kill the existing dynos (if you have preboot enabled they will only be killed after all traffic is redirected to the new dynos);

When you deploy on Railway, the process is different:
1. SSH into each server web server, one by one;
2. Perform a `git pull` to get the newest version of the code;
3. Run `bundle install` if `Gemfile.lock` changed;
4. Run `yarn install` if the `yarn.lock` changed;
5. Run `assets:precompile`;
6. Run `db:migrate`;
6. Perform a rolling restart of Puma and Sidekiq;

Because Railway does not have to install Ruby and other packages, and because it retains the existing EC2 instances, it is much, much faster at deploys than Heroku. It takes seconds for Railway to have all requests to your app running the new code. By comparison, Heroku goes through a minutes long (10 in my apps case) slug compilation step, then a 3-7 minutes preboot process.

On the other hand, Heroku has a serious advantage when it comes to scaling. Since Heroku always has an up to date image (the slug), scaling up is as simple as booting the dynos. On the other hand, Railway starts from an outdated AMI, which it then has to execute a normal deploy process.

Put it simply: Railway is much faster at deploys, Heroku is much faster at scaling.

#### Wait, isn't it bad to keep reusing the same EC2/dyno?
That was one of my major sticking points when I thought about all the time I'd have to spend maintaining my own servers. Heroku teaches us to treat our servers/dynos as discardable and build our apps with the assumption that anything they do on them will be wiped at least once a day (the daily restart). I agree with this 100% (if you don't understand the reason, check the [12-factor app manifesto](https://12factor.net/)).

What makes it confusing is that Heroku creates and destroys instances so frequently that programmers like us, who don't know anything about devops, start thinking that's the only way to do things. I'll not try to guess why Heroku does it, but it's obvious their use case requires it. However, we once again have an advantage over Heroku: we only care about our own app.

It is perfectly fine to keep your servers around: 
- Railway has a playbook that you can run once in a while to update your servers without taking your app offline;
- Logs are handled by `systemd` which imposes a limit on how much disk space they can use;
- The EC2 instances you will use have 2x (`c6i`) or 4x (`m6i`) more memory than `standard-2x` dynos and `jemalloc` pre installed, which should eliminate any memory related problems (unless your app has some serious leak);

## Load Balancer
Any production grade app should be running on at least two web servers so that if one fails, the other can keep serving requests while you solve the problem. Or, something that is much more probable: so that when you restart puma in one server during a deploy, the other keeps serving requests. This means that if you want requests to be distributed between all servers you have running, you will need something between them and the rest of the world. That's where the load balancer comes in.

#### The Heroku Router
When you create an app in Heroku, it is given a unique URL that you use to create a CNAME in your DNS. After that requests to your domain will arrive at the Heroku Router, which will assign them to one of your dynos at random and that's it. Everything "just works".

#### Railway and the ELB
I promise that with Railway things also "just work". But it's useful to know what is happening behind the scenes. When you execute the `bootstrap_aws.yml` playbook, Railway will create the two pieces of your infrastructure that will handle the job of ensuring that requests are distributed between your various web servers: the load balancer and the target group.

Every instance of the AWS Load Balancer (ELB) is given a unique URL that you use to create a CNAME in your DNS, just like on Heroku. The load balancer that Railway creates is configured to receive requests only on port 443 (HTTPS) and automatically direct then to its target group. This means it more or less acts as a simple router.

The actual load balancing logic is in the Target Groups. The target group that Railway creates is aware of every EC2 instance running Puma, and it directs requests to then using Round Robin (instead of at random). To ensure it does not send a requests to an instance that is crashed it also regularly performs a GET on a specific URL (`api/health_checks`). If an instance does not reply to the GET request twice (or replies with a status code other than 200), the target group stops sending requests to it, until it becomes healthy again.

As long as you are using Railway to create new instances, you won't have to worry about registering them in the target group. Railway will handle that for you.

## Web and Worker servers
On Heroku creating web and worker dynos is as simple as adding a couple of entries to the `Procfile`:
```
web: bundle exec puma -C config/puma.rb
worker: bundle exec sidekiq -e production -C config/sidekiq.yml
```

But what is actually happening behind the scene? If all dynos are created from the same slug, why does one dyno become a "web" dyno and another a "worker" dyno? Well, I can't tell you how Heroku does it, but for Railway it's actually pretty simple: they have different unit files.

If you never heard of them, unit files are basically configuration files for `systemd`. Never heard of `systemd` either? Well, it's one of the packages that comes by default with Ubuntu and Railway uses it to ensure that when an EC2 instance boots, it has Puma/Sidekiq running. If you check [Puma's](https://github.com/puma/puma/blob/master/docs/systemd.md) and [Sidekiq's](https://github.com/mperham/sidekiq/blob/master/examples/systemd/sidekiq.service) repos you will see that both of them have a sample unit file and instructions on how to properly configure them.

Let's take a look at what Puma's file looks like in Railway:
```
[Unit]
Description=Puma HTTP Server
After=syslog.target network.target

[Service]
Type=notify
WatchdogSec=10
User=app
WorkingDirectory=/home/app/railway
SyslogIdentifier=puma

Environment=RAILS_MAX_THREADS=3
ExecStart=/home/app/.rbenv/shims/bundle exec puma -C /home/app/railway/config/puma.rb -p 3000
Restart=always

[Install]
WantedBy=multi-user.target
```

What does each line mean?
- `Description`: The name of this unit file;
- `After`: This tells `systemd` to only execute this unit file after the logging and network services have started;
- `Type`: Instructs `systemd` to wait until Puma or Sidekiq send it a notification before considering to have started sucessfully;
- `Watchdog`: After Puma and Sidekiq start, they will regularly ping `systemd` to tell it they are still running. This entry tells `systemd` how long to wait between pings before considering them to have failed;
- `User`: The user that `systemd` will used to execute the `ExecStart` command;
- `WorkingDirectory`: The directory that `systemd` will execute the `ExecStart` command from;
- `SyslogIdentifier`: Anything that Puma and Sidekiq print to STDOUT will be written to the system log. This line tells `systemd` what name to use as prefix for those lines;
- `Environment`: Used to set environment variables for the `ExecStart` command. Because Sidekiq and Puma require different values for the database connection pool, this is a good place to set it;
- `ExecStart`: This is the command that will be executed by this unit. As you can see, it is roughly equivalent to the `web:` line in Heroku's Procfile
- `Restart`: Tells `systemd` when it should attempt to restart the service after has failed.

If I were to translate, this file is saying: "Systemd, when this EC2 instance boots, wait until the logging and network services have started then use this command to run puma. If Puma doesn't send you a ping for longer than 10 seconds, I want you to forcibly restart it."

What about Sidekiq? Almost the same:
```
[Unit]
Description=Sidekiq Server
After=syslog.target network.target

[Service]
Type=notify
WatchdogSec=10
User=app
WorkingDirectory=/home/app/railway
SyslogIdentifier=sidekiq

Environment=RAILS_MAX_THREADS=13
ExecStart=/home/app/.rbenv/shims/bundle exec sidekiq -C /home/app/railway/config/sidekiq.yml
Restart=always

[Install]
WantedBy=multi-user.target
```

If you ever wondered how to configure Puma and Sidekiq to start when your instance boot, to ensure they are always running, and to collect their logs, this is how you do it: using `systemd`. If you tell Railway to create a web server, it will install the Puma unit file. If you tell it to create a worker server, it will install the Sidekiq unit file. 


