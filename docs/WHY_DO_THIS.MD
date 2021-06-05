# If you are not too sure about this whole thing...

I wasn't either, that's why I spent three years on Heroku before moving AWS. Even though I enjoyed my time there, I wish I had switched that much earlier. Unfortunately there were two things I was absolutely sure (and heard echoed from many others), that held me back:

1. **Deploying to a IaaS like AWS is hard**. To make matters worse, I had no experience with devops, the only part of AWS I knew how to use was S3, and my *unix admin skills were limited to what I learned over the years working on a Mac; 
2. **Keeping everything running is a full time job**. Not only would I have to handle the move alone, I'd have to keep everything running by myself. And I was already struggling to find enough hours to do all the coding I needed to keep my company alive;

What convinced me that those two things might be wrong, and that I actually had a shot at this, was an article by Marco Arment, former CTO of Tumblr: [Web Hosting For App Developers](https://marco.org/2014/03/27/web-hosting-for-app-developers). I recommend you take a look at it as its excellent, but it all comes down to a single thing he says:

"If you can write a halfway decent app, you can manage a Linux VPS in your sleep."

### Heroku already does everything I need
Awesome! When I started it did everything I needed too, and I'd probably have remained there if that was the case. But as my app grew it started deviating from the "golden path" that Heroku expects us to follow. Here's a few of the reasons why Heroku might not be the best option for your use case:

1. **It doesn't have a data center in your continent**. I live in Brazil and so do my users. A large portion of them are also on slow, high latency 3G/4G connections. The roundtrip to the US datacenter was making my app much slower than it needed to be;
2. **1GB of ram is just not enough for your app**. My app did not have a memory leak. I also had the jemalloc buildpack installed. But with the amount of image processing and PDF generation we were doing, we were constantly blowing through all the memory in the dynos. Paying 5x to 10x more was not an option.
3. **You need a package that is not available**. Heroku's linux images come with plenty of packages preinstalled and you can add more using the Aptfile. But the instant you need anything more complex, you are in trouble. I wanted to replace ImageMagick with libvips, but the version available in Ubuntu's for install through AptFile was too old for ActiveStorage. If I was on a normal VPS I'd be able to compile it from source, but on Heroku? You need a buildpack for that. Good luck finding one that works and does not make your slug larger than 500MB.
4. **Deploys are slow**. I've deployed Go and Java apps to Heroku. Super fast. My rails app? 10 minutes or more. I only had 1 package in my Aptfile (webp), and 2 buildpacks (chrome and jemalloc). Didn't matter. 

If any of those apply to you (specially items 1 and 2), then you should seriously consider moving away from Heroku as the benefits, in my opinion, greatly out weight the cost.

### It's way too hard
When you start, it's really hard. After you get the hang of it and automate most things, it's just as easy as Heroku. 

Remember: I was just a programmer when I started preparing to make the move. I knew nothing about devops, AWS to me meant S3, and I had only heard that Ansible existed. I was perfectly willing to pay for instruction, but even though I found many articles of companies talking about moving from Heroku to AWS/Google/Digital Ocean, no one had ever published a book or a course on how to do it. Even when I asked about it in the [CGRP Slack group](https://www.railsspeed.com), where there are a bunch of really smart, really experienced people, I had no luck.

So I had to do it the hard way. I bought a [course on AWS from Udemy](https://www.udemy.com/course/aws-certified-developer-associate-dva-c01/), a [book about Ansible](https://www.ansiblefordevops.com/) and sat down to study. Then I created a new project in Rubymine, and started testing things. It was my full time work for 2 weeks and at times it felt like I was punching a wall because things didn't make sense, didn't work the way I expected, or gave me errors I simply could not find the solution for.

But by the end of it, I had the first version of what eventually become Railway. Thanks to it, handling devops on AWS is just as easy as it was on Heroku, with a huge advantage: when I need to change something, it's much, much easier than it was on Heroku.

If you are coming at this from the same place I was, there's still going to be a learning period. But hopefully, if I did a good job with Railway, it's going to be much shorter than what I had to go through or you would expect.

### I don't have the time
Would you trade 1 hour of your week for more powerful and cheaper servers, more flexiblity in packages you have available, faster deploys, and the knowledge that if anything breaks you can easily fix it? Because that's the trade-off you are making.

We are programmers, we never to by hand what we can automate. And I built Railway to get the same level of automation I had on Heroku. Scaling up and down, updating or upgrading servers, downloading backups from your database, deploying and rolling back. If you were on Heroku's "Golden Path", Railway has got you covered.  

If you don't believe me, just refer back to Marco Arment's article: "Once you set everything up, you can leave it running largely untouched indefinitely. You’ll probably never be woken up at 3 AM to reboot anything or delete log files."

