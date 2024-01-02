# Route53 존 데이터 소스 선언 - 도메인을 사용하여 Route53 존 가져오기
data "aws_route53_zone" "this" {
  name = var.domain  # 사용할 도메인 이름
}

# Route53 헬스 체크 리소스 정의 - HTTP 헬스 체크 설정
resource "aws_route53_health_check" "this" {

  count = length(var.setSubdomains)  # Subdomain 개수에 따라 반복

  fqdn            = var.setSubdomains[count.index].dns_name  # 검사할 FQDN 설정
  port            = 80  # 포트 설정
  type            = "HTTP"  # HTTP 유형 설정
  resource_path   = "/"  # 리소스 경로 설정
  request_interval = 30  # 요청 간격 설정
  failure_threshold = 3  # 실패 임계값 설정

  tags = {
    Dns_Name = var.setSubdomains[count.index].dns_name  # DNS 이름 태그 설정
    Set_Identifier = var.setSubdomains[count.index].set_identifier  # Set 식별자 태그 설정
  }
}

# Route53 레코드 리소스 정의 - 헬스 체크 ID 및 Failover 라우팅 설정
resource "aws_route53_record" "this" {
  zone_id = data.aws_route53_zone.this.zone_id  # Route53 존 ID 설정

  count = length(var.setSubdomains)  # Subdomain 개수에 따라 반복

  name    = "${var.setSubdomains[count.index].subdomain}.${var.domain}"  # 원하는 서브도메인 설정
  type    = var.type  # 레코드 유형 설정

  set_identifier = var.setSubdomains[count.index].set_identifier  # Set 식별자 설정
  failover_routing_policy {
    type = var.failover_type  # Failover 유형 설정
  }

  // ALB 헬스 체크 구성
  health_check_id = aws_route53_health_check.this[count.index].id  # 헬스 체크 ID 설정

  alias {
    name                   = var.setSubdomains[count.index].dns_name  # ALB 이름 설정
    zone_id                = var.setSubdomains[count.index].zone_id  # ALB 존 ID 설정
    evaluate_target_health = true  # 대상 헬스 체크 평가 설정
  }
}
