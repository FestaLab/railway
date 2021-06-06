# If you are not too sure about this whole thing...
I remember that the first time I deployed my app to Heroku, it felt absolutely magical. I just pointed it to my Github repository and Heroku figured out that I had a Rails app, and gave me a web dyno and worker dyno, ready to run. A few clicks got me a Postgres database, a few more a Redis instance. Then I grabbed the unique url it assigned to my app, used it to create a CNAME in Cloudflare and I was done. It was an incredibly refined experience and one of the reasons that many developers swear by the company and would never consider anything else.

Heroku has been on the market for many years and has poured an incredible amount of money and engineering effort into its product. While Amazon and Google have tried to recreate this "it just works experience" with various services, it's arguable how successful they were.

That's why when most of us (me included) think about what it would take to get our apps running anywhere but Heroku it feels intimidating, if not downright impossible. Fortunately, **we are not trying to recreate Heroku**. We are only trying to get our own Rails app to production. This means that we need a much smaller subset of features than what Heroku offers and we can make assumptions to simplify our infrastructure that Heroku cannot.

Still, just because moving away from Heroku is possible it doesn't mean its worth it, right? Well, before I moved to AWS there were 3 arguments I used when people asked me I was on Heroku instead of AWS... 

### Heroku already does everything I need
Heroku has a "golden path" it expects you to follow and, as long as you do, all your needs are taken care of. For the first two years my app was like that. But by the third year we had started deviating from it, and what were originally minor annoyances started to become major problems. Instead of helping us, Heroku was making things much harder than they needed to be. Here are four problems we had, that other people I talked to have also mentioned:   

1. **Heroku doesn't have a data center in all continents**. I live in Brazil and so do my users. A large portion of them are also on slow, high latency 3G/4G connections. The round trip to the US datacenter was making my app much slower than it needed to be;
2. **1GB of ram is just not enough for a Rails app**. My app did not have a memory leak. I also had the jemalloc buildpack installed. But with the amount of image processing and PDF generation we were doing, we were constantly blowing through all the memory in the dynos. Paying 5x to 10x more for the performance dynos would be a major increase in cost when we only needed a bit more memory;
3. **You are limited in what packages you can use**. Heroku's linux images come with plenty of packages preinstalled and you can add more using the Aptfile. But if you need anything more complex, you are in trouble. I wanted to replace ImageMagick with libvips, but the version available in installation through AptFile was too old for ActiveStorage. If I was on a normal VPS I'd be able to compile it from source, but on Heroku? You need a buildpack for that. Good luck finding one that works and does not make your slug larger than 500MB.
4. **Deploys are slow**. I've deployed Go and Java apps to Heroku. Super fast. My rails app? 10 minutes or more. I only had 1 package in my Aptfile (webp), and 2 buildpacks (chrome and jemalloc). Didn't matter. 

I tolerated those problems for an entire year, because I thought that...  

### Running my own servers is too hard
Oh yes, I agree with that one actually. When you are starting its ridiculously hard. But that's usually how its goes when you are learning something new. After you get the hang of it and, like any self respecting programmer, automate everything, it's just as easy as Heroku. Easier even.

Back when I committed myself to making the move I was just a programmer. My *nix skills were limited to what had I learned on Mac, "devops" to me meant clicking buttons on Heroku, AWS was just S3, and I didn't even know Ansible was a thing. To make matters worse, even though I was perfectly willing to pay for instruction, there were no books or courses I could buy on how to deploy Rails to AWS. Even when I asked about it in the [CGRP Slack group](https://www.railsspeed.com), where there are a bunch of really smart, really experienced people, I had no luck.

So I had to do it the hard way. I bought a [course on AWS from Udemy](https://www.udemy.com/course/aws-certified-developer-associate-dva-c01/), a [book about Ansible](https://www.ansiblefordevops.com/) and sat down to study. After I was done, I created a new project in Rubymine, and started testing things. It was my full time work for 2 weeks. Those were some of the most frustrating weeks in my life. I was constantly having to search google for how to do the simplest things, trying to understand what an obscure error message meant, or banging my head against the table out of frustration because things did not work the way I expected them to work.  

But by the end of it, I had the first version of what eventually become Railway. What's more, not only it could do almost everything Heroku did for me, it made me understand HOW Heroku did those things. It was like spending years wondering how a magician did those magick tricks, and one day you got a look behind the curtains and everything 'clicked' into place.

If you are coming at this from the same place I was (only programming experience), there's still going to be a learning period. But hopefully, if I did a good job with Railway, it's going to be much shorter than what I had to go through or you would expect.

This leads us to the final argument, which is...

### I definitely do not have the time to do this
Would you trade 1 hour of your week for more powerful, cheaper and closer servers, faster deploys, and the ability to make changes to your servers so they better fit your apps needs? Because that's the trade-off you are making.

Before I discovered Ansible I kept thinking of all the time I'd have to spend deploying my app by hand, updating operating systems, configuring new servers when I needed to scale up, fixing things that broke, waking up at night due to a server going down, etc. I barely had enough time to do all the coding I needed to keep my company alive, I couldn't afford the time required to keep my own servers running.

By comparison, on Heroku you can do everything with the click of a button, or a CLI command. That's not magic. It's simply the result of Heroku's engineers sitting down and building all that automation. If they did it, we can do it too (remember: we don't need to recreate Heroku, only a fraction of its features).

We even have a major advantage that there are tools like Ansible that make building that level automation easier and faster than when Heroku started.

With Railway you won't even have to do that. It already comes out of the box with the ability to create your entire infrastructure from scratch, scale up and down, deploy and rollback, update and upgrade, download database backups and more.

### The final straw 
If I still have not convinced you, then I'm going to point you to the one article that got me thinking that I actually had a shot at this: [Web Hosting For App Developers](https://marco.org/2014/03/27/web-hosting-for-app-developers), by Marco Arment, former CTO of Tumblr. As he so succinctly put it:

"If you can write a halfway decent app, you can manage a Linux VPS in your sleep."
