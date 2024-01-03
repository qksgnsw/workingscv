# Backend

```sh
go mod init github.com/workingscv/dev/backend
# 버젼이 맞지 않아 
# 이전 버젼으로 구성한다.
go mod tidy -go=1.20
# 빌드
go build -o app cmd/backend/main.go

# secret manager 이전
DB_HOST={{ DB_HOST }} ./backend_{{ OS }}_{{ ARCH }}
#  secret manager 이후
ENV=prod SECRET_NAME={{ DBCredentials_SECRET_NAME }} ./backend_{{ OS }}_{{ ARCH }}
```

ENV=prod SECRET_NAME=rds\!db-cc73e095-5610-477d-afda-060859956653 ./backend_linux_x86_64

ENV=dev DB_HOST=workingscv-master.cvthkx2gfpla.ap-northeast-2.rds.amazonaws.com ./backend_linux_x86_64


ENV=dev DB_HOST=workingscv-replica.cryoigw06ouk.ap-northeast-1.rds.amazonaws.com ./backend_linux_x86_64