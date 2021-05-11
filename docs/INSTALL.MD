# INSTALL

Before we start, let's set some expectations: **this is not going to be easy**. There are a lot of things involved in getting your machine and your AWS/Github accounts properly configured to use this project. And then even more to get it working with your own rails apps. After you are done with this install guide, you still have to go through the "[First Run](https://github.com/FestaLab/railway/blob/main/docs/FIRST_RUN.MD)" guide to get your AWS infrastructure up and running.
 
This is why I'll suggest that you use the [railway-app](https://github.com/FestaLab/railway_app) for your first deploy to AWS. It's a small rails app that has just enough functionality to ensure all parts of the setup are working. This way you can be sure that any problems you run into are related to Ansible or AWS, not something in your app that you forgot to configure in your app.

Also, this is not going to be cheap and it most definitely won't fit the free tier. This project is supposed to handle the devops needs a small tech company. If you bring up both development and production environments, we are talking about, at a minimum, 6 EC2, 3 RDS, 4 elasticache, 2 Load Balancer, plus Cloudwatch.

Finally, if you are only checking Railway out of curiosity and would prefer to not have to uninstall everything by hand later, I recommend using Vagrant. In fact, everything I've written in these guides, I tested in a Vagrant box using `ubuntu/focal64`.

### CliffsNotes on Ansible
Here are a few things you should know:

1. Think of Ansible as a way to automate everything that linux administrators used to do by hand;
2. A `task` is an instruction for Ansible to do something. e.g.: download a file, execute a command, set a permission, etc.;
3. A `role` is a combination of `tasks` that together do something useful. e.g.: build libvips from source, install Cloudwatch integration, etc.;  
4. A `playbook` is a combination of `roles` that together automate a major part of your day to day devops work. e.g.: deploy your app, create a new AMI, etc.;
4. An `inventory` is a list of EC2 instances that Ansible will control. Railway has an inventory for production and another for QA of branches;
5. Files called `var` contain variables. e.g.: the version of ruby you use, the url of the repository your project is in, etc.;
6. Files called `vault` are similar to `var`, except they are encrypted.;

During these install instructions, if I ask you to give something a specific name (e.g.: `elasticache-pg-noeviction`), **please use that exact name**. Just like Rails expects things to be named in a certain way so it can find them, so does Railway. After we get everything working and you get familiar with it, you can go back and make the changes you want.

### STEP 1: Preflight Check
There's a few things we will need installed before we can start.

#### 1.1 If you are on MacOS
Start by installing `homebrew`, a package manager we will use for the rest of the installation.
```shell
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Then install command line tools, which are used by homebrew for some packages. If for some reason the installation fails, follow instructions [here](https://github.com/nodejs/node-gyp/blob/master/macOS_Catalina.md).
```shell
xcode-select --install
```

Next we need to install python, which is required by Ansible. We will do that using `pyenv`. Start by running this command:
```shell
brew install pyenv
```

Then these two to ensure it's loaded in the current terminal and that it will load in new terminals:
```shell
eval "$(pyenv init -)"
echo 'eval "$(pyenv init -)"' >> ~/.zshrc
```

Finally install python. There are newer versions, but this is the one Railway was tested on:
```shell
pyenv install 3.8.10
pyenv global 3.8.10
```

We are done here. Go to STEP 2.

#### 1.2 If you are on Ubuntu (Focal Fossa)
Start by updating system packages:
```shell
sudo apt update -y
```

Then install a few packages we will need:
```shell
sudo apt-get install -y build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev python-openssl git make
```

Next we need to install python, which is required by Ansible. We will do that using `pyenv`. Start by running this command:
```shell
curl https://pyenv.run | bash
```

Then these to ensure that it will load on new terminals and it is loaded in the current one:
```shell
echo 'export PATH="~/.pyenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(pyenv init -)"' >> ~/.bashrc
echo 'eval "$(pyenv init --path)"' >> ~/.profile
exec $SHELL
```

Finally install python. There are newer versions, but this is the one Railway was tested on:
```
pyenv install 3.8.10
pyenv global 3.8.10
```

Close your current terminal window (or ssh session if you are using Vagrant) and open a new one.
```shell
python --version
```

It should show `Python 3.8.10`. We are done here. Go to STEP 2.

### STEP 2: Install Ansible
Now that the preparation steps are out of the way, let's install Ansible:
```
pip install --upgrade pip
pip install ansible
```

Then all the modules that Railway relies on:
```
ansible-galaxy collection install amazon.aws
ansible-galaxy collection install ansible.posix
ansible-galaxy collection install community.general
```

### STEP 3: Configure your AWS region of choice
There are a few things that Railway cannot do automatically for you in AWS, so we will handle those now.

#### 3.1 IAM Roles
First we are going to create two users with program for ansible. Go to `IAM -> Users -> Add User`.

Name the first one `ansible-readonly`, give it `Programmatic access` and on the next step choose `Attach existing policies directly`. Add the following:  
1. `AmazonEC2ReadOnlyAccess`
2. `AmazonVPCReadOnlyAccess`
3. `AmazonElastiCacheReadOnlyAccess`
4. `AmazonRDSReadOnlyAccess`
5. `CloudWatchReadOnlyAccess`
6. `AmazonS3FullAccess`
7. `ElasticLoadBalancingFullAccess`

Name the second one `ansible-fullaccess`, give it `Programmatic access` and on the next step choose `Attach existing policies directly`. Add the following:
1. `AmazonEC2FullAccess`
2. `AmazonVPCFullAccess`
3. `AmazonElastiCacheFullAccess`
4. `AmazonRDSFullAccess`
5. `CloudWatchFullAccess`
6. `AmazonS3FullAccess`
7. `ElasticLoadBalancingFullAccess`
8. `IAMFullAccess`

Store their credentials somewhere for now. In step 3 we will secure them inside a `vault` file.

Next, we must create an `instance_profile_name` for our EC2 instances.

Go to `IAM -> Roles -> Create Role`.
- Select type of trusted entity: `AWS Service`
- Choose a use case: `EC2`

Click `Next`. Look for a policy called `CloudWatchAgentServerPolicy` and check it. This will allow our EC2 instances to send logs and collectd metrics to Cloudwatch.

You can skip adding Tags. 

Give the role the name `railway-iam-ec2-role`. Click `Create Role`.

#### 3.2 EC2 Key pairs
We are not going to allow password login in our EC2 instances. Instead of will create two Key Pairs, which Ansible and us will use to ssh into them.

Go into `EC2 -> Network & Security -> Key Pairs -> Create key pair`. Configuration:
- Name: `ansible-ec2-development`
- File format: `PEM`

After you click `Create key pair` again, the file will be automatically downloaded. For second the pair:
- Name: `ansible-ec2-production`
- File format: `PEM`

Store their credentials somewhere for now. In step 3 we will encrypt them using Ansible.

#### 3.3 Server certificates
To get https working we have to create a certificate for ELB to use. So head to `Certificate Manager` and under `Provision Certificates` click  `Get Started`.

1. Choose `Request public certificate`, then click `Request a certificate`;
2. In `Domain name`, type in the domain you will use for your app, then click `Next`;
3. Choose `DNS Validation`, then click `Next`;
4. Ignore the tags and click `Review`;
5. Check everything is correct and click `Confirm and request`;
6. Expand the table with the Domain/Validation Status columns and grab the `Name` and `Value` columns;
7. Head to your DNS host and create a new CNAME with those two;
8. Go back to AWS and click `Continue`.

You are done here.

#### 3.4 S3 Bucket
We will need an S3 bucket to store our production dumps so that we can later download them to our computers and restore them to the development environment.

Head to `S3 -> Buckets` and click `Create a bucket`.
- Bucket name: Choose anyone you want
- AWS region: Use the same region you are going to deploy your app
- Block all public access: Make sure this is checked
- Bucket versioning: No need to enable this. RDS has it's own form of backups, these dumps are just for our convenience.

Click "Create bucket". Store the bucket name somewhere. We will need it later

### STEP 4: Fork the companion app
To deploy new versions of the your app Ansible will need to have access to the repository's deploy key.  

Since we are going to use the `railway-app` to test our installation, go ahead and [fork it](https://github.com/FestaLab/railway-app).

Next, follow Github's guide on how to create and add deploy keys to your repo by [clicking here](https://docs.github.com/en/developers/overview/managing-deploy-keys#deploy-keys).

When given the choice, do NOT check `Allow write access`. Ansible will not need it.

Next, go into the global vars file of this project, located in `group_vars -> all -> vars`, and change the `github_repository_url` var to the one of your fork of `railway-app` repo.

### STEP 5: Fork this project
You are going to have to make changes to this project in the future, to make it work with your own projects, so fork it into your repository and then clone it to your computer.

#### 5.1 Change the encryption password for the vaults
First thing to do, is to change the password of the `vaults`. We are going to use two passwords. One for development, and one for production. For your own sanity, choose something you can remember and won't mind typing... a LOT.

For development, execute the `decrypt` line, type `railway123` as the password, then execute the `encrypt` line and type your new password.  
```shell
ansible-vault decrypt inventories/development/group_vars/all/vault
ansible-vault encrypt inventories/development/group_vars/all/vault
```

For production, execute the `decrypt` line, type `railway123` as the password, then execute the `encrypt` line and type your new password.
```shell
ansible-vault decrypt inventories/production/group_vars/all/vault
ansible-vault encrypt inventories/production/group_vars/all/vault
```

For the rest of this guide, when I mention "password of the development vault" and "password of the production vault", I'm talking about these two passwords.

#### 5.2 Change the AWS region in the inventories
Next, go into the two `aws_ec2.yml` files in this project and change the value under `region` to the AWS region you want to use:
```yml
regions:
  - us-east-1
```

Then can into the global var file under `group_vars -> all -> vars` and do the same.
```shell
aws_region: us-east-1
```

#### 5.4 Change the host name of your app
Next, go into the `vars` file located in `group_vars -> all` and replace `app_host` with the domain you used to create the certificate in step 3.3. e.g.:
```shell
app_host: railway.festalab.com.br
```

#### 5.5 Change the the backup bucket
Then can into the global var file under `group_vars -> all -> vars` and replace the backup bucket with the one you created in step 3.4.
```shell
aws_backup_bucket: railway-rds-backups
```

#### 5.6 Insert and protect your deploy key
Now we are going to start using the vaults and Ansible's file encryption to secure our keys and credentials.

In the folder `roles -> ansible_credentials -> app_bootstrap -> files` you will find two folders named `development` and `production` with an empty file called `deploy_id_rsa` inside. 

Copy the content of the **private** deploy key you created on step 3 to BOTH of them. I know this sounds weird but there is a reason for that: every time you execute an Ansible playbook, it will ask for the password of the vault. It will then also use that password to decrypt every encrypted file it encounters. Since we are going to use different passwords for development and production, we also need to have the deploy key encrypted with two different password.

So go ahead and encrypt both keys. For the key in the `development` folder use the password of the development vault. For the one in the `production` folder use the password of the production vault.

```shell
ansible-vault encrypt roles/app_bootstrap/files/development/deploy_id_rsa
ansible-vault encrypt roles/app_bootstrap/files/production/deploy_id_rsa
```

#### 5.7 Insert and protect your EC2 keypairs
In the folder `roles -> aws_ec2_create -> files` you will find two empty `.pem` files. Replace them with the EC2 keys we created in step 3.2, and encrypt them.

```shell
ansible-vault encrypt roles/aws_ec2_create/files/ansible-ec2-development.pem
ansible-vault encrypt roles/aws_ec2_create/files/ansible-ec2-production.pem
```

#### 5.8 Insert and protect the credentials of the IAM users and the certificate ARN
The last set of protected credentials are going into the vaults instead of a separate file.

Let's start with the development vault.
```shell
ansible-vault edit inventories/development/group_vars/all/vault
```

Ansible will open the file in VIM, and you will see it has 6 entries. 

Replace `vault_aws_access_key` and `vault_aws_secret_key` with the credentials of your READ ONLY user. 

Replace `vault_aws_certificate_arn` with the ARN of the certificate we created in step 3.3. You can find it by going to `Certificate Manager`, clicking the certificate and looking for `ARN`. The value should start with `arn:aws:acm`. 

Replace `vault_aws_rds_username`, `vault_aws_rds_password` and `vault_aws_rds_database` with values of your choice. If you are a lazy person like me, just go into one of your rails projects and execute `ActiveStorage::Blob.generate_unique_secure_token` three times, using them as username, password and database (make sure your database name and user name start with a letter)

Repeat the procedure for the production vault, but this time give it the credentials of the FULL ACCESS user. 

```shell
ansible-vault edit inventories/production/group_vars/all/vault
```

#### 5.9 Insert and protect the master.key
Go back to your fork the `railway-app`, grab the `master.key` and place it both in `roles -> app_bootstrap -> files -> development` and `roles -> app_bootstrap -> files -> production`. Then encrypt both with the correct passwords. It's the same procedure we did with the `deploy_id_rsa`.

```shell
ansible-vault encrypt roles/app_bootstrap/files/development
ansible-vault encrypt roles/app_bootstrap/files/production
```

#### 5.10 Get the ID of the base Ubuntu LTS ami in your region
Go to `EC2 -> Launch Instance` and find the option that says "Ubuntu Server 20.04 LTS (HVM), SSD Volume Type". Right next to it are two AMI ids, one for x86 and one for ARM. Grab the x86 one. Currently, in US-EAST-1, that's `ami-09e67e426f25ce0d7`.

Next, go into the global vars file of this project, located in `group_vars -> all -> vars`, and update the `aws_ami_id` var.
```shell
aws_ami_id: ami-09e67e426f25ce0d7
```

### STEP 6: Run the bootstrap playbooks 
Finally we have to run one or two playbooks, depending on your role.

### 6.1 You and every developer that should have access to the development environment
The playbook named `bootstrap_ansible_development` will do the following:
1. Install the boto libraries and awslogs;
2. Copy the development keypair to your local `.ssh` folder;
3. Copy the credentials of the READ ONLY user to the local AWS folder.

Before doing all that, it will ask your for a password. It is, you guessed it, the password for the development vault.

You will get multiple warnings. Ignore them. Ansible is complaining because its trying to load the inventory of servers from AWS but it still doesn't have the credentials for that.
```shell
ansible-playbook bootstrap_ansible_development.yml
```

#### 6.2 You and every developer that should have access to the production environment
The playbook named `bootstrap_ansible_production` will do the following:
1. Copy the production key to your local `.ssh` folder;
2. Copy the credentials of the FULL ACCESS user to the local AWS folder, overriding the READ ONLY credentials.

Before doing all that, it will ask your for a password. It is, you guessed it, the password for the production vault. The command however, is a bit different this time.
```shell
ansible-playbook bootstrap_ansible_production.yml -i inventories/production/aws_ec2.yml
```

The `-i` tells Ansible which `inventory` it should use for the playbook you are running. For safety reasons, this project is configured to use the development inventory by default. This means that when you want to run any of the playbooks with `production` in the name, you will have to add this `-i` parameter.

The last thing I must call your attention for is the final step of each playbook. Go ahead and open both of them, then compare lines 21, 22, 23.

Notice that they are identical? And yet in one playbook you get the READ ONLY user, and in the other the FULL ACCESS one? Well, that's because when you are running the development playbook, the development vault will be used. When you are using the production playbook, the production vault will be used.

This allows us use the same `roles` for different environments.

### YOU ARE DONE!
Congratulations. You have reached the end of the install instructions. Now head to the "[First Run](https://github.com/FestaLab/railway/blob/main/docs/FIRST_RUN.MD)" guide to continue.
