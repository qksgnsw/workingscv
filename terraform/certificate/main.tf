resource "aws_acm_certificate" "this" {
  domain_name       = var.domain
  validation_method = "DNS"

  subject_alternative_names = [
    var.domain,
    "*.${var.domain}"
  ]

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Environment = "test"
  }
}

data "aws_route53_zone" "this" {
  name = var.domain
}

resource "aws_route53_record" "validation" {
  # zone_id = var.host_zone_id  # Route 53 Hosted Zone ID
  zone_id = data.aws_route53_zone.this.zone_id

  for_each = {
    for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
}

resource "aws_acm_certificate_validation" "this" {
  certificate_arn = aws_acm_certificate.this.arn
  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]
  timeouts {
    create = "5m"
  }
}