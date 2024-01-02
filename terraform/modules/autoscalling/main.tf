# 로컬 변수 선언
locals {
  name     = var.name
  env      = var.env

  user_data = var.user_data

  tags = {
    Project_Name = local.name
    Env          = local.env
  }
}

# Security Group 모듈 설정
module "alb_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "alb_sg"
  description = "This is an SG of alb_sg."
  vpc_id      = var.vpc_id

  egress_rules = ["all-all"]

  ingress_cidr_blocks = [
    "0.0.0.0/0"
  ]

  ingress_rules = [
    "http-80-tcp",
    "https-443-tcp"
  ]

  tags = merge(
    { Name : "${local.name}-alb_sg" },
    local.tags
  )
}

# 오토스케일링을 위한 EC2 설정
resource "aws_launch_configuration" "as_templete" {
  name_prefix   = "${local.name}-asg-"
  image_id      = var.image_id 
  instance_type = var.instance_type                  

  security_groups = var.security_groups

  user_data_base64 = base64encode(local.user_data)

  iam_instance_profile = var.iam_instance_profile
}

# Application Load Balancer(ALB) 설정
resource "aws_lb" "alb" {
  name               = "${local.name}-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [module.alb_sg.security_group_id]
  subnets            = var.alb_subnets

  # 삭제 방지
  enable_deletion_protection = false

  tags = merge(
    { Name : "${local.name}-alb" },
    local.tags
  )
}

# 타겟 그룹 설정
resource "aws_lb_target_group" "tg" {
  name     = "${local.name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}

# ALB 리스너 설정(HTTP)
resource "aws_lb_listener" "alb80listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      host        = "#{host}"
      path        = "/#{path}"
      port        = "443"
      protocol    = "HTTPS"
      query       = "#{query}"
      status_code = "HTTP_301"
    }
  }
}

# ALB 리스너 설정(HTTPS)
resource "aws_lb_listener" "alb443listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "443"
  protocol          = "HTTPS"

  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

# 오토스케일링 그룹 설정
resource "aws_autoscaling_group" "asg" {
  name_prefix          = "${local.name}-asg-"
  launch_configuration = aws_launch_configuration.as_templete.name
  min_size             = var.min_size
  max_size             = var.max_size
  desired_capacity     = var.desired_capacity
  vpc_zone_identifier  = var.vpc_zone_identifier
  health_check_type    = "ELB"
  target_group_arns    = [aws_lb_target_group.tg.arn] # ALB 리소스 이름 지정

  tag {
    key                 = "Name"
    value               = "${local.name}-instance"
    propagate_at_launch = true
  }
}

# CPU 스케일 아웃 정책 설정
resource "aws_autoscaling_policy" "cpu_scale_out_policy" {
  autoscaling_group_name = aws_autoscaling_group.asg.name
  name                   = "${local.name}_cpu_scale_out_policy"
  adjustment_type         = "ChangeInCapacity"  # 인스턴스 개수 조정 방식

  metric_aggregation_type = "Average"
  estimated_instance_warmup = 300

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50  # 50%
  }

  policy_type = "TargetTrackingScaling"
}
