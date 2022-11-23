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
7. Ubuntu 22.04;
8. No containers;

It relies the following services in AWS:
1. EC2 for webservers and workers;
2. Elasticache for Redis;
3. RDS for postgres;
4. Cloudwatch for logging and server metrics;
5. ELB for Load Balancer;

Railway does not try to be web scale. It's targeted at small dev teams (or sole developers) who have a single person who does devops on the side. It was born and battle tested at [FestaLab](https://festalab.com.br/) where we use it daily.

## Where do I start?
I've always been a fan of those "choose your own adventure" game books, so let's do the same here:

- If you are not sure about this whole moving from Heroku to AWS thing, [click here](https://github.com/FestaLab/railway/blob/main/docs/WHY_DO_THIS.MD);
- If you would like to know more about the infrastructure that Railway will create, [click here](https://github.com/FestaLab/railway/blob/main/docs/THE_PARTS_OF_RAILWAY.MD);
- If you are ready to start your journey, [click here](https://github.com/FestaLab/railway/blob/main/docs/INSTALL.MD);
- If you have already done the install steps and want to bring up the infrastucture, [click here](https://github.com/FestaLab/railway/blob/main/docs/FIRST_RUN.MD);
- If you already have the sample app running, and need to change things to make your app work with Railway, [click here](https://github.com/FestaLab/railway/blob/main/docs/CUSTOMIZATION.MD);
- If your app is running in production and you want to know to handle your day to day needs, [click here](https://github.com/FestaLab/railway/blob/main/docs/DAY_TO_DAY_WORKFLOW.MD);

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/FestaLab/railway. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/FestaLab/railway/blob/main/CODE_OF_CONDUCT.md).

If you with to submit pull requests, please check the [contribution guide](https://github.com/FestaLab/railway/blob/main/docs/CONTRIBUTE.MD) to make handling your credentials easier.

## License

The project is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Railway project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/FestaLab/railway/blob/main/CODE_OF_CONDUCT.md).

