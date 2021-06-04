# CUSTOMIZATION

Here you can change Ansible behavior and the AWS resources that will be created.

### The Global Vars File
This file is named `vars` and is located in the folder `group_vars -> all`.

```yaml
---
# AWS
aws_redis_version: "5.0"
aws_redis_version_id: "redis5.0"
aws_redis_port: 6379
aws_postgres_version: "13"
aws_postgres_version_id: postgres13
aws_region: us-east-1
aws_ami_id: ami-09e67e426f25ce0d7

# Ruby
ruby_version: 3.0.1

# Github
github_repository_url: git@github.com:FestaLab/railway-app.git
github_branch: main

# App
app_name: railway
app_host: railway.festalab.com.br

# Ansible stuff
ansible_override_puma_config: true
ansible_override_sidekiq_config: true
ansible_override_database_config: true
ansible_build_image_libs: false
ansible_use_static_build_for_ffmpeg: false
```

#### AWS
The entries here should be self explanatory. They will tell Ansible which version of Redis to use in Elasticache, which version of Postgres to use in RDS, which region to use, and what ubuntu AMI to build on. If you decide to change these values, there are a few things to pay attention to:

1. The Ansible module for Elasticache does not support version 6 yet;
2. The AMI we create will come with the client for version 13 installed. If you change it here, you must change it there too;
3. I have only tested these playbooks on Ubuntu 20.04, so I'm not sure if they will work on another version. I'm 100% sure they will not work on another distro (like CentOS);

#### Ruby
I've only tested the compilation of `3.0.1` in this project, but I have no reason to believe you would have any trouble with others. No matter the version you choose, Ansible will ensure its installed with `jemalloc`, which should greatly reduce your memory usage.

#### App
Changing values here should be done with care. The key `app_name` is used in all playbooks to define names of folders in EC2 machines, resources in AWS, and files in this project. When changing it to the name of your app, follow these steps:
1. Change the value in this file;
2. Find all instances of `- hosts: _railway_` in this project and replace with `- hosts: _YOUR_APP_NAME_`
3. Go into both `aws_ec2.yml` and replace `tag:Environment: railway-app-ENVIRONMENT` with `tag:Environment: YOUR-APP-NAME-app-ENVIRONMENT`

#### Github
These should be replaced with your repository url and the primary branch (`master` if you are in an older project, `main` if you are in a newer one). The `url` is fixed and used by all playbooks, while the branch is used as a default, but various playbooks can choose other options. Example:
```yaml
ansible-playbook deploy_development.yml -e "group_id=0 branch=cool-feature"
ansible-playbook deploy_production.yml -e "version=GIT_SHA"
```

#### Ansible
The entries here control the behavior of various playbooks.

- Override Puma Config: Railway comes with a `puma.rb` file that it copies over your projects `config/puma.rb`, and is adapted to work with the environment variables available in this project. If prefer to use your own `puma.rb` file, change the value here to `false`, but make sure to use it as a reference on how to change your own file.
- Override Sidekiq Config: Railway comes with a `sidekiq.rb` and `sidekiq.yml` files that it copies over your projects `config/initializers/sidekiq.rb` and `config/sidekiq.yml`, and is adapted to work with the environment variables available in this project. If prefer to use your own `sidekiq.rb` file, change the value here to `false`, but make sure to use it as a reference on how to change your own file.
- Override Database Config: Railway comes with a `database.yml` file that it copies over your projects `config/database.yml`, and is adapted to work with the environment variables available in this project. If prefer to use your own `sidekiq.rb` file, change the value here to `false`, but make sure to use it as a reference on how to change your own file.
- Build Image Libs: By default Railway will install the image_magick and libvips versions available in ubuntu's official repository. If you prefer newer versions, set it to `true` and Railway will get the source and build them;
- Use Static Build for FFMPEG: Same as above, but instead of compiling from source a static build will be used

### The Environment Vars Files
Next we have the two environment specific `vars` files under `inventories -> development -> group_vars -> all` and `inventories -> development -> group_vars -> all`. The important entries there are:

```yaml
# AWS
infra_rds_instance_type: "db.t3.micro"
infra_rds_size: "50"
infra_rds_backup_retention: "7"
infra_rds_read_replica: false
infra_redis_cache_instance_type: "cache.t3.micro"
infra_redis_job_instance_type: "cache.t3.micro"
infra_ec2_web_instance_type: "t3.micro"
infra_ec2_worker_instance_type: "t3.micro"
infra_ec2_web_scaling_min: 1
infra_ec2_worker_scaling_min: 1

# App
app_max_threads: 3
app_puma_concurrency: 2
app_sidekiq_concurrency: 10
```

#### AWS
These control the types of EC2, Elasticache and RDS instances that will be created.
- `infra_rds_instance_type`: The RDS instance type that will be used for your database. Choose a value from [this page](https://aws.amazon.com/rds/instance-types/);
- `infra_rds_size`: How much disk space your RDS instance will have;
- `infra_rds_backup_retention`: Your RDS instance will be setup with daily backups. This value defines how long these backups wil be kept;
- `infra_rds_read_replica`: Whether to create a read replica for your database or not.
- `infra_redis_cache_instance_type`: The Elasticache instance type that will be used for your cache instance. Choose a value from [this page](https://aws.amazon.com/elasticache/pricing/)
- `infra_redis_job_instance_type`: Same as above, for the job instance.
- `infra_ec2_web_instance_type`: The EC2 instance type that will be used for your web instances. Choose a value from [this page](https://aws.amazon.com/ec2/instance-types/)
- `infra_ec2_worker_instance_type`: Same as above, but for worker instances;
- `infra_ec2_web_scaling_min`: The number of EC2 instances running Puma;
- `infra_ec2_worker_scaling_min`: The number of EC2 instances running Sidekiq;

If this is your first time having to make these decisions, and you are not sure, what to choose, here's a few "rules of thumb" for your production environment:
- `infra_rds_instance_type`: Choose the `db.r6g` that has the same amount of RAM that you are using on Heroku;
- `infra_redis_cache_instance_type`: If you are only using this for fragment caching you can use a `t3` that has the same amount of memory as your Heroku addon;
- `infra_redis_job_instance_type`: If you are only using this to store sidekiq jobs, you can use a `t3` that has the same amount of memory as your Heroku addon;
- `infra_ec2_web_scaling_min`: Exactly 2. Puma has no trouble with high concurrency, so it's better to scale vertically (more powerful instances), since this will reduce the chance of a request being sent to a server with a high load;
- `infra_ec2_worker_scaling_min`: At least 2. Sidekiq does not like high concurrency values, so you will need to scale horizontally (add more instances);
- `infra_ec2_web_instance_type`: Use the `c5` family. Decide how many Puma workers you want, divide that number by 2 (since that's how many web servers you will have), then find the instance that has that many vCPUs. e.g.: If you want 16 workers, you need two instances with 8vCPUs. That's the `c5.2xlarge`;
- `infra_ec2_worker_instance_type`: If you are mostly sending email with your workers, the `t3.micro` micro should be enough. Otherwise go with `c5.large`

The `t` family is the cheapest in AWS, but they have very weak CPUs that can only temporarily burst to high performance, before having to "rest" for a period of time. Because of that they are terrible under sustained load. However sending emails (ec2 worker) or fetching values from memory (elasticache) is not a demanding activity, so the `t` instances should be able to handle it without having to burst.

The `r` family has the most amount of memory for the lowest prices. This makes it perfect for postgres, since having enough memory to keep your entire dataset in memory will have the biggest impact on performance;

The `c` family has the best processors for the lowest prices. They come with "only" 2GB of ram per vCPU, but that's still twice as much as your app had on a standard-2x dyno on Heroku, with the advantage that Railway uses jemalloc by default. This makes it perfect for your web servers.

### App
The values here are extremely important.

`app_max_threads`: How many threads each Puma worker will have, and how many connections to the database each Puma worker can use;
`app_puma_concurrency`: How many workers the Puma process will have;
`app_sidekiq_concurrency`: How many threads the Sidekiq process will have;

If you already have an app in production you are probably familiar with the correct values for each of these, but let's review:
`app_max_threads`: 3 is good enough, 5 if you must;
`app_puma_concurrency`: 1 per vCPU in your EC2 instance;
`app_sidekiq_concurrency`: 10 or less. Sidekiq [does not like high concurrency](https://github.com/mperham/sidekiq/issues/3892);

If you are worried about that connection pool of `3` with a concurrency of `10` for Sidekiq, don't be. The [unit file](https://github.com/FestaLab/railway/blob/main/roles/app_worker_server/templates/sidekiq.service.j2) will override that value and set it to `app_sidekiq_concurrency + 3`.
