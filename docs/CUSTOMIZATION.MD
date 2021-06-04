# CUSTOMIZATION

Welcome to the customization guides. The topics below have their own dedicated guides.

- [Ansible and AWS](https://github.com/FestaLab/railway/blob/main/docs/customization/ANSIBLE_AWS.MD);
- Puma configuration;
- Sidekiq configuration;

### Database
Here's the base template:

```yaml
default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") %>

production:
  <<: *default
  database: <%= ENV['AWS_RDS_DATABASE'].presence %>
  username: <%= ENV['AWS_RDS_USERNAME'].presence %>
  password: <%= ENV['AWS_RDS_PASSWORD'].presence %>
  host: <%= ENV['AWS_RDS_HOST'].presence %>
  port: 5432
```

The `ENV` variables for this configuration are coming from: 

- `RAILS_MAX_THREADS`: the environment specific `vars` file. Defaults to `3`;
- `AWS_RDS_DATABASE`: the environment specific `vault` file. You chose this during in STEP 3 of the install guide; 
- `AWS_RDS_USERNAME`: the environment specific `vault` file. You chose this during in STEP 3 of the install guide;
- `AWS_RDS_PASSWORD`: the environment specific `vault` file. You chose this during in STEP 3 of the install guide;
- `AWS_RDS_HOST`: from AWS. Ansible will handle this for you automatically; 

#### Health checks 
The load balancer needs to know which instances are healthy in order to direct traffic to them. It does that by performing a `GET` to a specific URL and checking if the response code is `200`. Make sure you have this piece of code in your `routes.rb` file:
```ruby
get 'api/health_check', to: proc { [200, {}, ['']] }
```
