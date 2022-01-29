locals {
  datadome_cidr = "172.42.0.0/16"

  private_subnets = [
    cidrsubnet(local.datadome_cidr, 4, 0),
    cidrsubnet(local.datadome_cidr, 4, 1),
    cidrsubnet(local.datadome_cidr, 4, 2),
  ]

  public_subnets = [
    cidrsubnet(local.datadome_cidr, 4, 3),
    cidrsubnet(local.datadome_cidr, 4, 4),
    cidrsubnet(local.datadome_cidr, 4, 5),
  ]
}

# Use VPC module to create private subnets for datadome and intra subnets for firewalls
module "vpc_datadome" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.11.4"

  name = "datadome-vpc"
  cidr = local.datadome_cidr
  azs = [
    "eu-west-3a",
    "eu-west-3b",
    "eu-west-3c"
  ]

  private_subnets       = local.private_subnets
  private_subnet_suffix = "private"

  public_subnets       = local.public_subnets
  public_subnet_suffix = "public"

  # Configure one NAT gateway per AZ.
  enable_nat_gateway = true

  # Metadata
  tags = local.common_tags
}
