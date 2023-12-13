# DB Module

### Description

- 서브넷 그룹과 보안그룹이라는 최소한의 옵션으로 가장 기본적인 db instance를 구성하는 모듈입니다.
- master-slave 나 read replica 같은 구성은 추후 구성 예정입니다.

##### require

1. 해당 db가 구성될 서브넷 그룹이 필요합니다.
2. 해당 db의 보안 그룹이 필요합니다.

##### Flow

1. 입력받은 서브넷으로 db의 서브넷 그룹을 만듭니다.
2. 입력받은 옵션으로 db 인스턴스를 생성합니다.