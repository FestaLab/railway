# CUSTOMIZATION

Welcome to the customization guide. Now that you've finished the installation and first run guides, and have the `railway-app` deployed to AWS, it's finally time to make necessary changes to this project and your own app to get it running on AWS.

### STEP 1: Global vars file
Let's start with the easiest one to understand. If you open `group_vars -> all -> vars`, this is what you will see
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

The entries under `AWS` should be self explanatory and you can safely change them without any impact. Make sure however that the values you in insert here are valid in AWS.

The single entry under `Ruby` should also be safe to modify. I've only tested the compilation of `3.0.1` in this project, but I have no reason to believe you would have any trouble with others.

The values under `App` are a bit more delicate. `app_name` is used in all playbooks to define names of folders in EC2 machines, resources in AWS, and files in this project. The procedure to changing the app name is:
1. Change the value in this file;
2. Find all instances of `- hosts: _railway_` in this project and replace with `- hosts: _YOUR_APP_NAME_`
3. Go into both `aws_ec2.yml` and replace `tag:Environment: railway-app-ENVIRONMENT` with `tag:Environment: YOUR-APP-NAME-app-ENVIRONMENT`

The entries under `Github` should be replaced with your repository url and the primary branch (`master` if you are in an older project, `main` if you are in a newer one). The `url` is fixed and used by all playbooks, while the branch is used as a default, but various playbooks can choose other options. Example:
```yaml
ansible-playbook deploy_development.yml -e "group_id=0 branch=cool-feature"
ansible-playbook deploy_production.yml -e "version=GIT_SHA"
```

Finally for the entries under `Ansible`:
- Override Puma Config: Railway comes with a `puma.rb` file that it copies over your projects `config/puma.rb`, and is adapted to work with the environment variables available in this project. If prefer to use your own `puma.rb` file, change the value here to `false`, but make sure to use it as a reference on how to change your own file.
- Override Sidekiq Config: Railway comes with a `sidekiq.rb` and `sidekiq.yml` files that it copies over your projects `config/initializers/sidekiq.rb` and `config/sidekiq.yml`, and is adapted to work with the environment variables available in this project. If prefer to use your own `sidekiq.rb` file, change the value here to `false`, but make sure to use it as a reference on how to change your own file.
- Override Database Config: Railway comes with a `database.yml` file that it copies over your projects `config/database.yml`, and is adapted to work with the environment variables available in this project. If prefer to use your own `sidekiq.rb` file, change the value here to `false`, but make sure to use it as a reference on how to change your own file.
- Build Image Libs: By default Railway will install the image_magick and libvips versions available in ubuntu's official repository. If you prefer newer versions, set it to `true` and Railway will get the source and build them;
- Use Static Build for FFMPEG: Same as above, but instead of compiling from source a static build will be used

### STEP 2: Environment var files
Next we have to two environment specific var files under `inventories -> development -> group_vars -> all - vars` and `inventories -> development -> group_vars -> all - vars`. The important entries there are:
```yaml
# AWS Infra
infra_rds_instance_type: "db.t3.micro"
infra_rds_size: "50"
infra_rds_backup_retention: "7"
infra_rds_read_replica: false
infra_redis_cache_instance_type: "cache.t3.micro"
infra_redis_job_instance_type: "cache.t3.micro"
infra_ec2_web_instance_type: "t3.micro"
infra_ec2_web_scaling_min: 1
infra_ec2_worker_instance_type: "t3.micro"
infra_ec2_worker_scaling_min: 1

# App
app_max_threads: 3
app_puma_concurrency: 2
app_sidekiq_concurrency: 10
```

These control the types of EC2, Elasticache and RDS instances that will be created, as well size of database pool, and number of puma and sidekiq workers. You can change them as you wish, as long as the values are valid in AWS.

Since Railway will install Ruby with jemalloc, I recommend you chose the `C` family instead of the `M` family if you decide that the `T` is not enough for your app.

### You are done
For now this is it for the customization guide. To finish, head to the [day to day workflow guide](https://github.com/FestaLab/railway/blob/main/docs/DAY_TO_DAY_WORKFLOW.MD).
