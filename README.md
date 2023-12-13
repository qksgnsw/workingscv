# Working SCV Project

### Architecture
![](./images/architecture01.png)

- [ ] 서울리전
- [ ] 일본리전

### 실행
- .tfvars 파일 만들어 참조해야 함.
```sh
terraform init
terraform validate
terraform plan

terraform apply -var-file={{ YOUR_ENV_FILE_NAME }}.tfvars -auto-approve

terraform destroy -var-file={{ YOUR_ENV_FILE_NAME }}.tfvars
```

### 1. Infra
---
- [x] Infra


  - [x] vpc 생성


  - [x] Internet Gateway 생성


  - [x] 퍼블릭 서브넷 생성
    - [x] 라우팅 테이블 생성


  - [x] webserver-was 프라이빗 서브넷 생성
    - [x] 라우팅 테이블 생성


  - [x] db 프라이빗 서브넷 생성
    - [x] 라우팅 테이블 생성


  - [x] NAT Gateway 생성
    - [x] EIP 생성

### 2. Servers
---
- [ ] Servers


  - [ ] OpenVPN
    - [x] 보안 그룹
    - [x] 구독관련된 내용이라 일단 BastionHost로 진행
    - [ ] 추후 openVPN 구축 가능성


  - [ ] Web Server
    - [x] 보안 그룹
    - [x] ALB
        - [x] 보안그룹
        - [x] SSL
        - [ ] Autoscaling
            - [ ] Templete
              - [ ] 프론트앤드 앱
            - [x] policy


  - [ ] WAS
    - [x] 보안 그룹 
    - [x] ALB
        - [x] 보안그룹
        - [x] SSL
        - [ ] Autoscaling
            - [ ] Templete
              - [ ] 앱
            - [x] policy


  - [ ] DB
    - [x] 보안 그룹
      - [ ] 퍼블릭 공개가 되어있는지 확인했는가?
      - [ ] database subnet에 배포되어있는지 확인
    - [x] SSL 인증서
    - [ ] Secret manager를 활용한 자격증명 보안
      - [ ] Secret manager로 키 생성
    - [ ] was와의 연결 확인
      - [x] cli 연결
      - [ ] was와의 연결
    - [ ] 정책 및 세팅 설정
      - [ ] Master-slave 구현

### 3. Services
---
- [ ] Service


  - [ ] Route53
    - [x] 인증서
      - [x] 생성
      - [x] 도메인 검증
    - [x] 레코드 등록
      - [ ] openVPN..?
      - [x] WebServer
      - [x] WAS
    - [ ] 장애조치 라우팅
    - [ ] 지역기반 라우팅


  - [ ] Global Accelator


  - [ ] S3

  - [ ] CoudFront


  - [ ] Code 시리즈
    - [ ] Code pipeline
    - [ ] Code Commit
    - [ ] Code build
    - [ ] Code deploy
    - [ ] Cloud watch
    - [ ] Event Bridge

### 4. dev
```sh
# 개발 소스 위치
cd ./workingscv
```
---
- [x] frontend
  - [ ] 웹서버 설정하기 
  - [x] 은우가 하기로 함
    - [ ] CloudFront 사용 가능성
    - [ ] S3 사용 가능성


- [ ] backend
  - [ ] db 
    - [x] 스키마
      - [x] 자동 생성 만들기
      - [x] 디비 통신 확인
      - [x] 쿼리 작동 확인
    - [ ] RDS와 연결하기
      - [x] 로컬 사설 db로 연결
      - [x] RDS 공개 액세스로 연결
      - [ ] private subnet에서 연결
        - [ ] cli 연결
        - [ ] 앱 연결
          - [ ] id/password로 연결
          - [ ] secret manager 연결
  - [x] api
    - [x] Create
    - [x] Update
    - [x] Delete
    - [x] Get
