# Route Module

### Description

- 가장 기본적인 요소들로 단순라우팅을 설정하는 모듈입니다.
- 지역기반, 가중치기반, 장애조치 등 추가 기능은 추후 추가 예정입니다.

##### require

1. 기본 도메인이 필요합니다.
2. 레코드 타입이 필요합니다.

##### Flow

1. 해당 도메인에서 zone_id를 가져 옵니다.
2. setSubdomains에 설정한만큼 서브 도메인을 만들어 등록합니다.
   1. 옵션에는 alb의 DNS 주소와 해당 alb의 zone_id가 필요합니다.
