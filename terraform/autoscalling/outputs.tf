output "dns_name" {
  value = aws_lb.alb.dns_name
}

output "load_balancer_type" {
  value = aws_lb.alb.load_balancer_type
}

output "subnets" {
  value = aws_lb.alb.subnets
}

output "zone_id" {
  value = aws_lb.alb.zone_id
}

output "availability_zones" {
  value = aws_autoscaling_group.asg.availability_zones
}

output "max_size" {
  value = aws_autoscaling_group.asg.max_size
}

output "min_size" {
  value = aws_autoscaling_group.asg.min_size
}
