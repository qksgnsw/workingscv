# ACM(AWS Certificate Manager) 인증서 리소스 정의 - 도메인 이름과 유효성 검사 방법 설정
resource "aws_acm_certificate" "this" {
  domain_name       = var.domain  # 도메인 이름 설정
  validation_method = "DNS"  # 유효성 검사 방법(DNS) 설정

  subject_alternative_names = [  # 대체 주소 설정
    var.domain,
    "*.${var.domain}"
  ]

  lifecycle {
    create_before_destroy = true  # 생성 전 파괴 설정
  }

  tags = {
    Environment = "test"  # 환경 태그 설정
  }
}

# Route53 존 데이터 소스 선언 - 도메인을 사용하여 Route53 존 가져오기
data "aws_route53_zone" "this" {
  name = var.domain  # 사용할 도메인 이름
}

# Route53 레코드 리소스 정의 - ACM 인증서 유효성 검사 레코드 생성
resource "aws_route53_record" "validation" {
  # zone_id = var.host_zone_id  # Route 53 Hosted Zone ID
  zone_id = data.aws_route53_zone.this.zone_id  # Route53 존 ID 설정

  for_each = {
    for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name  # 리소스 레코드 이름 설정
      record = dvo.resource_record_value  # 리소스 레코드 값 설정
      type   = dvo.resource_record_type  # 리소스 레코드 유형 설정
    }
  }

  allow_overwrite = true  # 덮어쓰기 허용 설정
  name            = each.value.name  # 이름 설정
  records         = [each.value.record]  # 레코드 설정
  ttl             = 60  # TTL(Time To Live) 설정
  type            = each.value.type  # 유형 설정
}

# ACM(AWS Certificate Manager) 인증서 유효성 검증 리소스 정의
resource "aws_acm_certificate_validation" "this" {
  certificate_arn = aws_acm_certificate.this.arn  # 인증서 ARN 설정
  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]  # 유효성 검증 레코드 FQDN 설정

  timeouts {
    create = "5m"  # 타임아웃 설정
  }
}
