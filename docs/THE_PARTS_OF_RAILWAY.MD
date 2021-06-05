# The Parts of Railway
Here's a quick reference for various components that a Rails app usually uses on Heroku, and what each one was replaced with on AWS.

| Component     | Heroku           | AWS                           |
| ------------- |------------------|-------------------------------|
| Web Server    | Web Dynos        | EC2 with Puma service         |
| Worker Server | Worker Dynos     | EC2 with Sidekiq service      |
| Database      | Heroku Postgres  | RDS with Postgres Engine      |
| Redis         | Heroku Redis     | Elasticache with Redis Engine |
| Logs          | LogPlex          | Cloudwatch                    |
| Metrics       | Dashboard        | Cloufwatch                    |
| Load Balancer | Heroku Router    | Elastic Load Balancer (ELB)   |

## ELB


## EC2


## RDS


## Elasticache


## Cloudwatch


## Virtual Private Network


## S3
