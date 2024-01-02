# data "aws_route53_zone" "this" {
#   name = var.domain
# }

# resource "aws_route53_record" "this" {
#   zone_id = data.aws_route53_zone.this.zone_id

#   count = length(var.setSubdomains)

#   name    = "${var.setSubdomains[count.index].subdomain}.${var.domain}" # Replace with your desired subdomain
#   type    = var.type

#   alias {
#     name                   = var.setSubdomains[count.index].dns_name
#     zone_id                = var.setSubdomains[count.index].zone_id
#     evaluate_target_health = true
#   }
# }

data "aws_route53_zone" "this" {
  name = var.domain
}

resource "aws_route53_health_check" "this" {

  count = length(var.setSubdomains)
  
  fqdn            = var.setSubdomains[count.index].dns_name
  port            = 80
  type            = "HTTP"
  resource_path   = "/"
  request_interval = 30
  failure_threshold = 3

  tags = {
    Dns_Name = var.setSubdomains[count.index].dns_name
    Set_Identifier = var.setSubdomains[count.index].set_identifier
  }
}

resource "aws_route53_record" "this" {
  zone_id = data.aws_route53_zone.this.zone_id

  count = length(var.setSubdomains)

  name    = "${var.setSubdomains[count.index].subdomain}.${var.domain}" # Replace with your desired subdomain
  type    = var.type

  // Change from simple routing to failover routing
  set_identifier = var.setSubdomains[count.index].set_identifier
  failover_routing_policy {
    type = var.failover_type 
  }

  // ALB health check configuration
  health_check_id = aws_route53_health_check.this[count.index].id

  alias {
    name                   = var.setSubdomains[count.index].dns_name
    zone_id                = var.setSubdomains[count.index].zone_id
    evaluate_target_health = true
  }
}
