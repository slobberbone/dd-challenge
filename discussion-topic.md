# Simple web server
### What are the first metrics you would put in place to monitor this component ? Why ?
I would monitor requests rate, response times and error rates of the application. 
First, response time would increase in case of any bottlenecking at any level and then error rates would follow if there is too much trafic to handle for our backend.
Of course those 2 metrics would be correlated with the requests.

### How would you make it scale to support 50K requests per second?
Let's say we did some benchmark on our instances and we are using the best specs for our backend, I would configure the ASG to scale horizontaly based on previous metrics.

### How would you secure the application ?
- run a serie of security checks within the CI piepline to minimize risks of injection, xss and other common attack vectors.
- add encryption wherever it is possible
- make use of role management and access control
- automate secrets rotation
- multiple HTTP security headers
  - CORS
  - Secure frames
- centralize application logs

### How would you secure the infrastructure ?
The actual infrastructure is already pretty safe for our application.
I would use datadome to enhance security against bad bots.
I would also add an SIEM to analyze the whole infrastructure trafic.

### How would you secure the release pipeline ?
I would run the whole pipeline in private subnets and then release the application through hoster's API if possible (SSM).
- ensure CI/CD cannot be bypassed
- run automated tests (deps/container scanning)
- automate secrets rotation


# Ansible Nginx
### Describe how you would secure deployments in this particular context (environment usage, access control...)
I don't think there is a safer way to handle the deployment.


# AWS Knowledges
You currently have an EC2 instance hosting a web application.
The number of users is expected to increase in the coming months, and hence you need to add more elasticity to your setup
Which of the following methods can help add elasticity to your existing setup?
Choose 2 answers from the options given below. Explain why.
1. Setup your web app on more EC2 instances and set them behind an Elastic Load balancer
2. Setup an Elastic Cache in front of the EC2 instance
3. ~~Setup your web app on more EC2 instances and use Route53 to route requests accordingly~~
4. ~~Setup DynamoDB behind your EC2 Instances~~
> I would setup more ec2 instances behind an ALB and add maybe an elasticache layer if it suits the application design but elasticache would go behind instance as data caching, I would use cloudfront for frontal caching.

What are bastion hosts? When should we use them?
> Bastion hosts are used to jump to another network, it being th only entrypoint to the network.

What are AWS spot instances? Explain a scenario in which this approach would be useful.
> Spot instances are instances that have a dynamic pricing depending of the availability / demand ratio, we should bid on them to get them. AWS can stop our instance whenever they want (almost as an event is triggered to prevent us that the instance will be deleted in a few minutes).
>This kind of instances can be useful for pipeline build as we don´t need them to be up 24/7.


# ElasticSearch
Could you explain why there are different roles for nodes (Coordinating, Master, etc.)? What are their differences?
- Master are used to route the trafic to different nodes within the cluster, these are the instances reached from other services.
- Coordinating nodes are used to coordinate sharding across the cluster
- Data nodes hosts shards and handle data operation (CRUD/search)
  - Hot nodes handle the 'hot' data, usualy having high IOs avialables. 
  - Warm store data that is still being accesed but not updated.
  - Cold usually read only data
- Ingest nodes are designed to ingest data into the cluster
- ML is used to do machine learning operation (i.e SIEM)

How would you secure access to the elastic search engine ? kibana ?
>Kibana is useful for log vieweing or data lookup but as nothing to do with security. I would setup xpack with SSL encryption and basic auth in the case of a free license.

How would you design a Highly Available ES cluster able to store 20K events (with a payload of 64kb each) per second?
> Looks like we are missing an important information here; the retention time we want.
> Here are some basic maths to estimate the number of objects stored over time and the needed storage to host it.
> Regardless of these info, I would at least have 3 masters and double or triple the amount of data nodes needed (depending of the cloud provider) to have at least 1 replica per shard.
> This infrastructure would cost a lot.

- ~1,3GBbps throughput
- Seconds, 20K docs - 1,3Gb
- Minutes, 1,2M docs - 78Gb
- Hour, 72M docs - 4,68 Tb
- Day, 1728M docs - 112,3 Tb
- Month,  51840M docs - 3369 Tb
