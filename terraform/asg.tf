module "webapp_asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "4.4.0"

  name = "webapp"
  # load_balancer_type = "application"

  # Launch template
  lt_name                = "webapp-lt"
  create_lt              = true
  use_lt                 = true
  update_default_version = true
  image_id               = local.ami_id
  security_groups        = [aws_security_group.webapp_instances.id]

  root_block_device = [
    {
      volume_type = "gp3"
      volume_size = "5"
    }
  ]

  # ASG
  desired_capacity          = 2
  min_size                  = 2
  max_size                  = 2
  health_check_type         = "EC2"
  instance_type             = "t3a.small"
  iam_instance_profile_name = aws_iam_instance_profile.webapp_profile.name
  target_group_arns         = module.webapp_alb.target_group_arns
  min_elb_capacity          = 1
  wait_for_capacity_timeout = "15m"

  vpc_zone_identifier = module.vpc_datadome.private_subnets

  tags_as_map = merge(local.common_tags, {
    role = "datadome-webapp"
    env  = "stg,prd"
  })

}
