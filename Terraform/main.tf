locals {
  name   = "${basename(path.cwd)}-${formatdate("YYYYMMDD", timestamp())}"
  tags = {
    Name       = local.name
    Example    = "${basename(path.cwd)}"
  }
}

data "aws_availability_zones" "available" {}

data "aws_ami" "MongoDB_AMI" {
  most_recent = true
  owners      = ["081291200450"]

  filter {
    name   = "name"
    values = ["Mongo-*"]
  }
}

data "aws_ami" "App_AMI" {
  most_recent = true
  owners      = ["081291200450"]

  filter {
    name   = "name"
    values = ["App-*"]
  }
}

data "aws_subnets" "all" {
  filter {
    name   = "vpc-id"
    values = [var.aws_vpc_id]
  }
}

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = local.name
  description = "Security group for Activity 2 usage with EC2 instance"
  vpc_id      = var.aws_vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "all-icmp", "ssh-tcp", "mongodb-27017-tcp"]
  egress_rules        = ["all-all"]

  tags = local.tags
}

resource "aws_instance" "mongodb" {
  ami                         = data.aws_ami.MongoDB_AMI.id
  instance_type               = var.aws_instance_type
  key_name                    = var.aws_pair_key
  
  #network config
  subnet_id                   = var.aws_subnet_id
  vpc_security_group_ids      = [module.security_group.security_group_id]
  associate_public_ip_address = true

  tags = {
    Name       = "${local.name}-DB"
    Example    = "${basename(path.cwd)}"
  }
}

resource "aws_instance" "App" {
  count = 2
  ami                         = data.aws_ami.App_AMI.id
  instance_type               = var.aws_instance_type
  key_name                    = var.aws_pair_key
  
  #network config
  subnet_id                   = var.aws_subnet_id
  vpc_security_group_ids      = [module.security_group.security_group_id]
  associate_public_ip_address = true

  tags = {
    Name       = "${local.name}-App-${count.index}"
    Example    = "${basename(path.cwd)}"
  }
  provisioner "remote-exec" {
    inline = [
      "echo '#!/bin/bash\nsudo sed -i \"s#const url =.*#const url = \\\"mongodb://MongoUser:myPassword@${aws_instance.mongodb.private_ip}:27017\\\";#g\" /home/ubuntu/app.js' > /tmp/init_script.sh",
      "chmod +x /tmp/init_script.sh",
      "/tmp/init_script.sh"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("./Keys/${var.aws_pair_key}.pem")
      host        = self.public_ip
    }
  }
}

resource "aws_security_group" "alb_sg" {
  name        = "alb_sg"
  description = "ALB security group"
  vpc_id      = var.aws_vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb_sg"
  }
}

resource "aws_lb" "app_alb" {
  name               = "app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.aws_subnets.all.ids

  enable_deletion_protection = true

  tags = {
    Name = "app-alb"
  }
}

resource "aws_lb_target_group" "app_alb_tg" {
  name     = "app-alb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.aws_vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 10
    interval            = 30
    path                = "/"
    port                = "80"
  }

  tags = {
    Name = "app-alb-tg"
  }
}

resource "aws_lb_listener" "app_alb_listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_alb_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "app_alb_tg_attachment" {
  count            = 2
  target_group_arn = aws_lb_target_group.app_alb_tg.arn
  target_id        = aws_instance.App[count.index].id
  port             = 80
}






