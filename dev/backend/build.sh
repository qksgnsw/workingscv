#!/bin/bash

build_dir="./dist"

go_file_path="./go.mod"
app_file_path="./$build_dir/backend"

if [ ! -d "$build_dir" ]; then
    mkdir "$build_dir"
fi

if [ -f "$go_file_path" ]; then
    rm -f go.*
fi

go mod init github.com/workingscv/dev/backend
go mod tidy -go=1.20

if [ -f "$app_file_path" ]; then
    rm -f backend*
fi

go build -o "./dist/backend" "./cmd/backend/main.go"

GOOS=linux GOARCH=amd64 go build -o "./dist/backend_linux_x86_64" "./cmd/backend/main.go"
GOOS=linux GOARCH=arm go build -o "./dist/backend_linux_arm" "./cmd/backend/main.go"

GOOS=windows GOARCH=amd64 go build -o "./dist/backend_win_x86_64" "./cmd/backend/main.go"
GOOS=windows GOARCH=386 go build -o "./dist/backend_win_x86" "./cmd/backend/main.go"

GOOS=darwin GOARCH=amd64 go build -o "./dist/backend_darwin_x86_64" "./cmd/backend/main.go"
GOOS=darwin GOARCH=arm64 go build -o "./dist/backend_darwin_arm64" "./cmd/backend/main.go"

echo "There is a built file in that directory: $build_dir"