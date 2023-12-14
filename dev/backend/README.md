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
SECRET_NAME={{ DBCredentials_SECRET_NAME }} ./backend_{{ OS }}_{{ ARCH }}
```

SECRET_NAME=testdb_20231214033021477700000001 ./backend_linux_x86_64