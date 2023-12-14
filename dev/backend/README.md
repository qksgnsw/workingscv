# Backend

```sh
go mod init github.com/workingscv/dev/backend
# 버젼이 맞지 않아 
# 이전 버젼으로 구성한다.
go mod tidy -go=1.20
# 빌드
go build -o app cmd/backend/main.go

DB_HOST={{ DB_HOST }} ./backend_{{ OS }}_{{ ARCH }}
```