# FIRST RUN

Good job on finishing the installation guide. Your computer is ready. Your github account is ready. Your AWS account is ready. 

It's time to start the long journey to get an app deployed to production. 

### STEP 1: Bootstrapping the development and production environments
When we deploy our apps to a PaaS like Heroku, they handle a lot of things for us. Placing them behind a load balancer, placing them inside a VPC, giving them access to our postgres and redis instances, etc. In AWS, Railway will handle that for us. Let's take a look at the contents of `bootstrap_aws.yml`:
```shell
- import_playbook: infra_vpc.yml
- import_playbook: infra_redis_cache.yml
- import_playbook: infra_redis_job.yml
- import_playbook: infra_rds.yml
```

The first thing you will notice is that it's possible for a playbook to import other playbooks. The second is that we are going to create four different pieces of our infrastructure now: a VPC, two Redis instances, and a Postgres instance.

If you don't care about the details of how this will happen, go ahead and jump to 1.5. On the other hand, if you'd like to understand how Railway is doing things, keep reading.

#### 1.1 Create the VPC
I'm only a beginner in most things AWS, so I will not embarrass myself by trying to explain what most of these are. Just think of them as "the things that I must have so that amazon will let my stuff talk to each other and the internet". I can hear the AWS experts in the audience cringing (I'd love if you guys could open an issue and tell me how to improve this. Or if you are in the [CGRP Slack](https://www.railsspeed.com/) you can DM me there).
1. Create a VPC named `railway-vpc-development`
2. Create a Subnet named `railway-subnet-development-a`
3. Create a Subnet named `railway-subnet-development-b`
4. Create an Elasticache Subnet named `railway-elasticache-subnet-development`
5. Create an RDS Subnet named `railway-rds-subnet-development`
6. Create an internet gateway named `railway-igw-development`
7. Create a route table named `railway-rtb-development`
8. Create a security group named `railway-sg-development`

### 1.2 Create the Redis instance dedicated to caching
Here we create an Elasticache instance with Redis and `maxmemory-policy` set to `allkeys-lfu`. We will use it for caching.
1. Create a parameter group named `elasticache-pg-allkeys-lfu` based on the `Redis5` default parameter group;
2. Change the `maxmemory-policy` to `allkeys-lfu`;
3. Create an Elasticache instance named `railway-elasticache-development-cache` with Redis as the engine, using the parameter group from step 1.

When the playbook is finished, AWS will still be creating the Elasticache instance. That's normal and should still take a while.

### 1.3 Create the Redis instance dedicated to jobs
Here we create an Elasticache instance with Redis and `maxmemory-policy` set to `noeviction`. We will use it to store our jobs.
1. Create a parameter group named `elasticache-pg-noeviction` based on the `Redis5` default parameter group;
2. Change the `maxmemory-policy` to `noeviction`;
3. Create an Elasticache instance named `railway-elasticache-development-job` with Redis as the engine, using the parameter group from step 1.

When the playbook is finished, AWS will still be creating the Elasticache instance. That's normal and should still take a while.

### 1.4 Create the Postgres instance.
Here we create a RDS instance with Postgres.
1. Create a parameter group named `railway-rds-pg-development`;
2. Obtain the subnet we created in step 1.1;
3. Obtain the security group we created in step 1.1;
4. Provision a postgres 13 rds instance with backup, maintenance window, etc.;
5. If production, provision a read replica for the primary database.

Just like creating caches, creating a RDS database takes a while. This time Ansible will wait until it's done.

### 1.5 Run the playbook
You will have to run this playbook twice. Once for development, once for production (you can leave production for later, we won't need it right now).
```shell
ansible-playbook bootstrap_aws.yml
ansible-playbook bootstrap_aws.yml -i inventories/production/aws_ec2.yml
```

Ansible will raise a warning saying that "provided hosts list is empty". Ignore it. It's because we still don't have any EC2 instances.

### STEP 2: Bootstrapping the development and production environments
It is now time for one of the most interesting parts of this project. Creating our very own custom AMI, with everything our projects are going to need baked in. Every PaaS has theirs, so we should have ours too right?

Now, creating an AMI takes a **long** time. I'd advise you to open the `ami_aws_setup.yml` file and replace `t3.small` with `c5.large` so that things go a bit faster.

If you open `ami.yml` this is what you will see:
```shell
- import_playbook: ami_aws_setup.yml
- import_playbook: ami_bootstrap.yml
- import_playbook: ami_packages.yml
- import_playbook: ami_app.yml
- import_playbook: ami_aws_snapshot.yml
```

Once again, if you don't care how this will happen, skip to 2.6. If you are actually interested in everything that goes into building a custom AMI, read on.

#### 2.1 Setup
Creates an EC2 instance using the base Ubuntu 20.04 LTS.
1. Find the subnet for the development environment;
2. Find the security group for the development environment;
3. Provision an EC2 instance with the name `railway-ec2-development-ami` using the `development` key pair;
4. Wait for the SSH server of the instance to come up;
5. Reload the `inventory` so that the other playbooks know that this instance exists.

#### 2.2 Bootstrap
Create a user for Ansible and the app to use.
1. Create a sudoer user for Ansible;
1. Create a sudoer user for the app;
2. Increase the resource usage limit for users.

#### 2.3 Packages
Install every package a Rails app needs, and configures the ones that are already installed.
1. Add repos for node and yarn;
2. Fully upgrade Ubuntu;
3. Setup time synchronization;
4. Enable cron;
5. Configure the firewall;
6. Copy over the ssh config that disables root login and password authentication;
7. Install collectd, which will send cpu, memory, etc. metrics to Cloudwatch;
8. Disable unnecessary services;
9. Install a variety of build tools;
9. Install python;
10. Install node and yarn;
11. Install postgres packages required for the `pg` gem to build;
12. Install Emoji typefaces;
13. Install Chrome for browser automation;
14. Install ffmpeg;
15. Install poppler;
16. Install Imagegick and libvips;
17. Install the latest ruby version with jemalloc;

If you need more packages feel free to add them here.

Railway can also install more recent versions of ffmpeg, image_magick and libvips then what is available in Canonical's repository. For that however it must eithre build them from source, or use static builds, which makes generating the AMI taking even longer. If you are interested go into the global vars file and change `ansible_build_image_libs` and `ansible_use_static_build_for_ffmpeg` to `true`.

#### 2.4 Install the the railway app
To make things a bit faster when we decide to create new instances, we are going to download our app and preinstall all its gems. The directory we download it too will NOT be used by later playbooks. I will skip a few steps in this explanation, since they don't matter much for the AMI. You can see the full set when I explain the EC2 of the webserver
1. Copy over the deploy key;
2. Download the latest version of our app from github;
3. Insert the master key;
6. Copy over a minimal set of `.rbenv-vars` file;
7. Install the latest release version of Rails;
8. Configure bundle to skip development and test gems;
9. Configure bundle to use as many cores are available;
10. Install the app bundle with bundler;
11. Install app packages with yarn;
12. Rerash rbenv to insert shims;
13. Precompile assets to ensure everything is working fine.

#### 2.5 Generate the AMI snapshot
Last step.
1. Create a snapshot of the EC2 instance under the name `railway-ami-TIMESTAMP`
2. Destroy the EC2 instance

#### 2.6 Run the playbook
You only need to run this playbook once. Like I said, it will take a while. Make yourself a Negroni, grab a good book and wait. 
```shell
ansible-playbook ami.yml
```

After some time the playbook will complete. Go to `EC2 -> Instances`, and you will see that the instance we used to build our AMI is no longer there. Then go to `EC2 -> AMIs` and you will see your timestamped AMI in there.

Every time you run the `ami.yml` playbook a new AMI will be created, and the other playbooks will start using it. Here's two advices I learned the hard way:

1. Thoroughly test new AMIs in the development environment before you send them to production;
2. If you decide to deregister old AMIs, keep at least the one that had been running in production.

### STEP 3: Deploying the Railway app to development
Now that all the infrastructure is ready, and we have our AMI, it's time to bring we webservers and workers and finally see everything running.

The contents of `setup_development.yml` are:
```shell
- import_playbook: setup_web_ec2.yml
- import_playbook: setup_web_development.yml
- import_playbook: setup_load_balancer.yml

- import_playbook: setup_worker_ec2.yml
- import_playbook: setup_worker_development.yml
```

This time I'll recommend you actually read through the explanations below, since if any problems come up with development, you will need to understand how it is set up to fix it.

#### 3.1 Create the webserver
This is where we will bring up an EC2 instance.
1. Get the latest AMI available;
2. Get the subnet of the development environment;
3. Get the security group of the development environment;
4. Bring up an EC2 instance with the AMI of step 1;
5. Wait for the SSH server of the instance to come up;
6. Refresh the `inventory` so that the other playbooks know this instance exist;

#### 3.2 Bootstrap the webserver
This is where we get the app running in the webserver.
1. Get the url of the development RDS instance;
2. Get the url of the cache Elasticache instance;
3. Get the url of the job Elasticache instance;
4. Configure Cloudwatch logging and metrics;
5. Install the app in the EC2 instance (check 2.4 for more details);
6. Insert over the deploy key
7. Download the latest version of the app from Github;
8. Insert the `master.key`;
9. Insert the amazon rds certificates;
10. Override `puma.rb` with one specific to AWS;
11. Override `sidekiq.rb` with one specific to AWS;
11. Override `database.yml` with one specific to AWS;
11. Override `sidekiq.yml` with one specific to AWS;
12. Insert the full set of `.rbenv-vars`
13. Bundle ruby gems
14. Install yarn packages;
15. Precompile assets;
16. Override `robots.txt` with one that prevents indexing;
17. Check if database exists, and create one if not;
18. Perform migrations;
19. Insert Puma's systemd file;
20. Reload systemd service;    
20. Enable Puma service;
21. Start Puma service

#### 3.3 Add the webserver to the load balancer
This is where we tell the load balancer that the instance exists, so it know to direct traffic to it
1. Get the VPC for the development environment;
2. Get the Security Group for the development environment;
3. Get the Subnet for the development environment;
4. Create a target group with a health check to `/api/health_check` and add the EC2 instance to it;
5. Create the load balancer with the target group of step 4;

#### 3.4 Create the worker
Same as 3.1

#### 3.5 Bootstrap the worker
This is where we get the app running in the worker.
1. Get the url of the development RDS instance;
2. Get the url of the cache Elasticache instance;
3. Get the url of the job Elasticache instance;
4. Configure Cloudwatch logging and metrics;
5. Install the app in the EC2 instance (check 2.4 for more details);
6. Insert over the deploy key
7. Download the latest version of the app from Github;
8. Insert the `master.key`;
9. Insert the amazon rds certificates;
10. Override `puma.config` with one specific to AWS;
11. Override `sidekiq.config` with one specific to AWS;
12. Insert the full set of `.rbenv-vars`;
13. Bundle ruby gems;
14. Install yarn packages;
15. Precompile assets;
16. Insert Sidekiq's systemd file;
17. Reload systemd service;
18. Enable Sidekiq service;
19. Start Sidekiq service.

#### 3.6 Run the playbook
You only need to run this playbook once. Like I said, it will take a while. Make yourself a Negroni, grab a good book and wait.
```shell
ansible-playbook setup_development.yml -e "group_id=0"
```

Notice the `-e`? That's how we specify extra variables that our ansible playbook should use. 

Railway is configured to allow up to 10 separate branches of your app to be deployed on the same set of webserver/worker/rds/elasticache, in order to keep costs down. 

With this command we are telling it to setup the dev environment `0`. It will listen on port `3000`, and the unit files will be `puma_dev0.service` and `sidekiq_dev0.service`

### 3.7 Check the result
Time to see our app running. To find out the IP of the weberver, use this command.
```shell
ansible-inventory --graph
```

You will get a result like this
```shell
@all:
  |--@_railway_app_development:
  |  |--34.227.10.225
  |  |--52.90.60.229
  |--@_railway_ec2_development_webserver:
  |  |--34.227.10.225
  |--@_railway_ec2_development_worker:
  |  |--52.90.60.229
  |--@aws_ec2:
  |  |--34.227.10.225
  |  |--52.90.60.229
  |--@ungrouped:
```

This is a list of all your development servers, grouped by tag. The IP we want is the webserver one:
```shell
|--@_railway_ec2_development_webserver:
  |  |--34.227.10.225
```

So copy that IP and paste it in your browser, followed by `:3000`.
```shell
http://34.227.10.225:3000
```

You will see rails default `scaffolding` for a `User` model. Create a new user, then refresh the page until the column `token` is filled. 

With this we know that RDS, Redis Cache and Redis Job and the worker server are all working.

#### Adding the domain and https support
Go to AWS and head to `EC2 -> Load Balancers`. There will be a single load balancer created, named `railway-alb-development-0`. Click it and copy its `DNS name`.

Go to your DNS host and create a CNAME for it. Example:
```
TYPE   NAME    CONTENT
CNAME  railway railway-alb-development-0-XXXXXXXX.us-east-1.elb.amazonaws.com 
```

Then go back to your browser and type that address
```
https://railway.festalab.com.br
```

### YOU ARE DONE!
You should see the user page again. Congratulations! Your first QA environment is ready! You can create new ones simply by replacing the value of the `group_id` var:
```shell
ansible-playbook setup_development.yml -e "group_id=1"
```

As for the production environment, it's pretty much the same. Simply drop the `group_id` and add the `inventory`:
```shell
ansible-playbook setup_production.yml -i inventories/production/aws_ec2.yml
```

Now head to the "[customization guide](https://github.com/FestaLab/railway/blob/main/docs/CUSTOMIZATION.MD)" to learn how to use Railway to handle everything your app needs.




