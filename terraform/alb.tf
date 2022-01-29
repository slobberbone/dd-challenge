module "webapp_alb" {
  source             = "terraform-aws-modules/alb/aws"
  version            = "6.2.0"
  name               = "webapp-alb"
  load_balancer_type = "application"
  internal           = false
  # splitter SG pour LB
  vpc_id          = module.vpc_datadome.vpc_id
  security_groups = [aws_security_group.webapp_alb.id] # A créer hors du module
  subnets         = module.vpc_datadome.public_subnets

  target_groups = [
    {
      name                 = "webapp-tg-80"
      backend_protocol     = "HTTP"
      backend_port         = 80
      target_type          = "instance"
      deregistration_delay = 150
      health_check = {
        protocol            = "HTTP"
        path                = "/health"
        matcher             = "200-401"
        interval            = 10
        unhealthy_threshold = 3
        healthy_threshold   = 3
      }
    },
    {
      name                 = "webapp-tg-81"
      backend_protocol     = "HTTP"
      backend_port         = 81
      target_type          = "instance"
      deregistration_delay = 150
      health_check = {
        protocol            = "HTTP"
        path                = "/health"
        matcher             = "200-401"
        interval            = 10
        unhealthy_threshold = 3
        healthy_threshold   = 3
      }
    }
  ]
  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    },
    {
      port               = 81
      protocol           = "HTTP"
      target_group_index = 1
    }
  ]
  tags = local.common_tags
}
