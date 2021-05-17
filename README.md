# Railway
Railway is a project for people who have apps running in a PaaS like Heroku and are looking to make the move to AWS. With a single command it can:

1. Create a custom AMI with everything a Rails app need;
2. Create a development/staging environment with webservers, workers, cache and job redis instances, postgres database and support for up to 9 branches of your app at the same time;
3. Create a production environment with load balanced webservers, workers, cache and job redis instances, postgres database with a read replica and rolling restarts;
4. Deploy to development/stating environment;
5. Deploy to production using rolling restarts;
6. Update production servers to get the latest security updates;
7. Upgrade production servers to a new AMI with zero downtime;
8. Compile ImageMagick and Libvips from source in order to get versions more recent, faster, and with more supported formats than the ones available in official repos;

To make all this work it makes some strong assumptions about the rails app it will deploy:
1. Puma as webserver;
2. Sidekiq as worker;
3. Redis as cache and job;
4. Postgres as database;
5. Node/Yarn for javascript;
6. [Majestic Monolith](https://m.signalvnoise.com/the-majestic-monolith/) instead of Microservices;
7. Ubuntu 20.04;
8. No containers;

It relies the following services in AWS:
1. EC2 for webservers and workers;
2. Elasticache for Redis;
3. RDS for postgres;
4. Cloudwatch for logging and server metrics;
5. ELB for Load Balancer;

Railway does not try to be web scale. It's targeted at small dev teams (or sole developers) who have a single person who does devops on the side. It was born and battle tested at [FestaLab](https://festalab.com.br/) where we use it daily.

*Leia em [portugues](https://github.com/FestaLab/railway/blob/main/README.pt.md)*.

## Installation

This is quite a complex project to install. Check the dedicated [install guide](https://github.com/FestaLab/railway/blob/main/docs/INSTALL.MD).

After that go through the [first run guide](https://github.com/FestaLab/railway/blob/main/docs/FIRST_RUN.MD) in order to get everything up and running.

## Usage

Again, quite complex. Check the dedicated [customization guide](https://github.com/FestaLab/railway/blob/main/docs/CUSTOMIZATION.MD) to learn how to adapt this project to your app.

After that go through the [day to day workflow guide](https://github.com/FestaLab/railway/blob/main/docs/DAY_TO_DAY_WORKFLOW.MD) to learn how to use Railway to handle your devops needs.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/FestaLab/railway. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/FestaLab/railway/blob/main/CODE_OF_CONDUCT.md).

If you with to submit pull requests, please check the [contribution guide](https://github.com/FestaLab/railway/blob/main/docs/CONTRIBUTION.MD) to make handling your credentials easier.

## Todo

1. Do not override application files, explain the changes instead;
2. Temporarily remove webserver from target group during a deploy for true zero downtime;
3. Fix Cloudwatch stream error when multiple instances use the same stream;
4. Cleanup how MAX_THREADS is configured in worker instances;

## License

The project is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Railwat project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/FestaLab/railway/blob/main/CODE_OF_CONDUCT.md).

