data "aws_route53_zone" "this" {
  name = var.domain
}

resource "aws_route53_record" "this" {
  zone_id = data.aws_route53_zone.this.zone_id

  count = length(var.setSubdomains)

  name    = "${var.setSubdomains[count.index].subdomain}.${var.domain}" # Replace with your desired subdomain
  type    = var.type

  alias {
    name                   = var.setSubdomains[count.index].dns_name
    zone_id                = var.setSubdomains[count.index].zone_id
    evaluate_target_health = true
  }
}

