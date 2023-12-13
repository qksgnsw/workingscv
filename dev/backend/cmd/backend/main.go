package main

import (
    "log"
    "net/http"

    "github.com/workingscv/backend/internal/handler"
)

func main() {
    http.HandleFunc("/memo", handler.Memo)
    http.HandleFunc("/memo/all", handler.GetAllMemos)

    log.Fatal(http.ListenAndServe(":8080", nil))
}
