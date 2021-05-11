# DAY TO DAY WORKFLOW

Now that everything works, it's time to understand how to use Railway in a daily base.

### Creating development areas
Railway has support for up to 10 development areas in a single set of ec2/elasticache/rds machines. Create them with:

```yaml
ansible-playbook setup_development.yml -e "group_id=0"
ansible-playbook setup_development.yml -e "group_id=1"
ansible-playbook setup_development.yml -e "group_id=2"
ansible-playbook setup_development.yml -e "group_id=3"
ansible-playbook setup_development.yml -e "group_id=4"
ansible-playbook setup_development.yml -e "group_id=5"
ansible-playbook setup_development.yml -e "group_id=6"
ansible-playbook setup_development.yml -e "group_id=7"
ansible-playbook setup_development.yml -e "group_id=8"
ansible-playbook setup_development.yml -e "group_id=9"
```

The number in `group_id` will determine the port that Puma uses, the database that the elasticache instances use, and the database that postgres uses:
- Puma: `puma.rb -p 300{{ group_id }}`;
- Elasticache: `redis://railway-elasticache-development-cache.cbpwde.0001.use1.cache.amazonaws.com:6379/{{ group_id }}`
- Postgres: `database: b05mh1q4hjazzula2x54g04wai3x90{{ group_id }}`

It will also determine the name of systemd unit files:
- Puma: `systemctl status puma_dev{{ group_id }}.service`
- Sidekiq: `systemctl status sidekiq_dev{{ group_id }}.service`

And finally the name of the load balancer you must grab the DNS Name to use in your DNS:
- Load Balancer: `railway-alb-development-{{ group_id }}`

When setting up new development areas, the master/main branch of your app will be deployed. If run the setup playbook in an area that already exists, **the current code will not be changed**. This is intentional.

If for some reason something breaks in one of the areas, simply delete its folder.
```shell
rm -rf ~/dev0
```

### Deploying to a development area
This one is pretty simple:
```shell
ansible-playbook deploy_development.yml -e "group_id=0 branch=YOUR_BRANCH"
```

Railway will download the new code, `bundle install`, `yarn install` and `db:migrate`, and then restart puma and sidekiq so that they pick the new configuration.

### Scaling up and down production
Unlike the development environment, production only supports a single app. However its playbook is capable of scaling up and down the number of servers.
```shell
ansible-playbook setup_production.yml -i inventories/production/aws_ec2.yml -e "web=4 worker=4"
```

When scaling up, new EC2 instances will be created. When scaling down, EC2 instances will be terminated.

### Deploying to production
Works the same way as the development one.
```shell
ansible-playbook deploy_production.yml -i inventories/production/aws_ec2.yml
```

If something goes wrong and you need to rollback
```shell
ansible-playbook deploy_production.yml -i inventories/production/aws_ec2.yml -e "version=GIT_SHA"
```
Railway will download the new code, `bundle install`, `yarn install` and `db:migrate`, and then do a rolling restart of puma on the webservers, followed by sidekiq on the workers;

### Updating production
To get the latest security updates on production
```shell
ansible-playbook update_ec2_production.yml -i inventories/production/aws_ec2.yml
```

### Upgrading production
To upgrade all EC2 instances in production to a new ami with zero downtime:

```shell
ansible-playbook upgrade_ec_2production.yml -i inventories/production/aws_ec2.yml
```

Railway will check how many webservers and workers EC2 instances currently exist, bring up the same number of EC2 instances running the new AMI, then terminate to old ones.


### Dumping the production database and restoring it to a dev area:
It's as simple as:
```shell
ansible-playbook database_dump_production.yml -i inventories/production/aws_ec2.yml
```

To restore that dump to one of the dev areas
```shell
ansible-playbook database_restore.yml -e "dump_type=full group_id=0"
```

To download it to you computer
```
ansible-playbook database_download.yml
```

I recommend having a `rake` task that can truncate your database and running it on `dev0`. Then you can do this to dump and restore the truncated version:
```shell
ansible-playbook database_dump_development.yml
ansible-playbook database_restore.yml -e "group_id=1"
```

### SSH into the EC2 instances
First get their IP:
```shell
ansible-inventory --graph
ansible-inventory --graph -i inventories/production/aws_ec2.yml
```

Then use the correct keypair:
```shell
ssh -i ~/.ssh/ansible-ec2-development.pem app@IP_ADDRESS
ssh -i ~/.ssh/ansible-ec2-production.pem app@IP_ADDRESS
```

If you are doing work in the development environment, any machine is fine. But if you are doing in production, use the dedicated `control` server.
