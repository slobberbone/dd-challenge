resource "aws_security_group" "webapp_instances" {
  name        = "webapp-instances-sg"
  description = "Datadome webapp SG"
  vpc_id      = module.vpc_datadome.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    self        = true

    security_groups = [aws_security_group.webapp_alb.id]
  }

  ingress {
    description = "HTTP_1"
    from_port   = 81
    to_port     = 81
    protocol    = "tcp"
    self        = true

    security_groups = [aws_security_group.webapp_alb.id]
  }

  egress {
    description = "All all outgoing trafic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "webapp_alb" {
  name        = "webapp-alb-sg"
  description = "Datadome webapp SG"
  vpc_id      = module.vpc_datadome.vpc_id

  ingress {
    description = "HTTP_80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP_81"
    from_port   = 81
    to_port     = 81
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All all outgoing trafic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
