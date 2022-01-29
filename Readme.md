# Introduction

There was originaly 2 exercises described in the challenge, the first one to write, dockerize and deploy a dummy webapp on a hosted service of our choice; the second to deploy 2 nginx vhosts using ansible. As these challenges can work together, I took the decision to merge and only build a single platform.

# App

Created a dummy flask webapp that say hi to people and add `X-Upstream-App` header based on `socket.gethostname()`.
The image has been manualy build and pushed to public docker hub registry using following commands:
```sh
docker build --tag hsfactory/datadome-webapp:latest .
docker push hsfactory/datadome-webapp:latest
```

# Terraform

We will use AWS cloud provider to deploy our application infrastructure in `eu-west-3` region.

## Usage

### Prerequisites

- AWS credentials configured with a profile named `perso`
- An AMI with SSM embedded

### Run

```
terraform apply
```
> Note that the ASG creation will wait for instances to be live on `:80/health`, so we should launch ansible provisoining in the same time, the terraform run will timeout otherwise.

## Network

- Using `172.42.0.0/16` range to allow enough hosts to handle potential scaling.
- Create a specific VPC which embed `public` and `private` subnets.
> We are using the terraform [terraform-aws-modules/vpc/aws](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest) module as it handle network resources creation for us.

## Amazon Machine Image

As we are using SSM to connect to our instances and thus not being shipped with standards AMIs, I had to build a custom AMI.
The AMI creation has been handled manually.
Here are the only shell commands that has been executed before creating a snapshot:
```sh
cd /tmp
REGION=$(curl http://169.254.169.254/latest/meta-data/placement/availability-zone)
wget "https://s3.$REGION.amazonaws.com/amazon-ssm-$REGION/latest/debian_amd64/amazon-ssm-agent.deb"
dpkg -i amazon-ssm-agent.deb
apt update
apt upgrade -y
```

## Application loadbalancer

An application loadbalancer hosted in the public subnet is in charge to redirect incoming traffic to healthy nodes within the private subnet.
> We are using the terraform [terraform-aws-modules/alb/aws](https://registry.terraform.io/modules/terraform-aws-modules/alb/aws/6.4.0?tab=inputs) module as it handle alb related resources creation for us.

## Autoscaling group

Instances creation is handled through an autoscaling group to allow infrastructure scaling.
This ASG define custom tags on instances to easily manage them through ansible dynamx inventory.
The `AmazonSSMManagedInstanceCore` AWS policy is attached to created nodes.
> We are using the terraforn [terraform-aws-modules/autoscaling/aws](https://registry.terraform.io/modules/HDE/autoscaling/aws/latest) module as it handle asg related resources creation for us.

## Security groups

### ASG

Only allow ports `80` and `81` from loadbalancers security group arn (also to itself as needed to handle live http probing as requested)

### ALB

Allow ports `80` and `81` from `0.0.0.0/0` 


# Ansible

## Usage

### Install galaxy roles

```sh
ansible-galaxy install -r galaxy.yml --force -p roles
```

### Install collections

```sh
ansible-galaxy install -r collections.yml
```

### Run

#### provisioning

```sh
AWS_PROFILE=perso ansible-playbook -i inventory/aws_ec2.yml local.yml
```

#### check_http_probes

```sh
AWS_PROFILE=perso ansible-playbook -i inventory/aws_ec2.yml check_http_probing.yml
```

## Inventory

Make use of [aws_ec2](https://docs.ansible.com/ansible/latest/collections/amazon/aws/aws_ec2_inventory.html) dynamic inventory.
Inventory config is based on instances roles set through terraform to retrieve desired hosts and build custom groups.

## Global configuration

As ec2 instances are place in a private subnet, they are not reachable outside of the `172.42.0.0/16` subnet.
We are making use of [AWS SSM](https://docs.aws.amazon.com/fr_fr/systems-manager/latest/userguide/ssm-agent.html) to connect and provision these instances.

## Roles

### docker

Using [geerlingguy.docker](https://galaxy.ansible.com/geerlingguy/docker) from galaxy roles repository to not reinvent the wheel.

### webapp

Quick ansible role creation to handle deployment of my awesome webapp.

### nginx

Using [geerlingguy.nginx](https://galaxy.ansible.com/geerlingguy/nginx) from galaxy roles repository to not reinvent the wheel.
As the original role does not provide a templating validation, I thought it was the opportunity to submit a [PR on github](https://github.com/geerlingguy/ansible-role-nginx/pull/230). It doesn't pass owner's CI tests so I just forked his role and added the validation diff here.

#### configuration

- delete default vhost
- add custom `X-Upstream-Nginx` header based on ansible `{{ inventory_hostname }}` variable.
- ability to independently deploy staging and production vhosts, each using a different port
    > Note that due to an ansible limitation a templating trick is being used to separate staging and production as it would normally be handled using different tags on nodes.
- generation of 4 vhosts
  - `default:80` and `default:81` with following rules to only handle healthcheck if the Host header is not specified:
    - `/` 403
    - `/ping` pong, used as nginx healthcheck
    - `/health` reverse proxified to the `/health` endpoint of our dummy application to check it's liveness
  - `devops-production.datadome.co:80` reverse proxy to our flask webapp
  - `devops-dev.datadome.co:81` reverse proxy to our flask webapp

### Check http probes

As http nodes are hosted in a private subnet, we would have needed to setup a specific host to check http probes which is a bit of a nonsense as we already have other nodes in the same subnet. We gonna use them randomly to check http probing on their neighbours.
As you can see in `ansible/roles/check-http-probing/tasks/main.yml` on `L8`, we are using any host in the related ansible group, excluding the one we are currently checking.

## Tags

Make use of tags on roles level to allow quicker config management.
