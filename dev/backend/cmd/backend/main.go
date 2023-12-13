package main

import (
	"log"
	"net/http"

	"github.com/workingscv/dev/backend/internal/handler"
)

func main() {
	http.HandleFunc("/", handler.Index)

	http.HandleFunc("/memo", handler.Memo)
	http.HandleFunc("/memo/all", handler.GetAllMemos)

	log.Fatal(http.ListenAndServe(":80", nil))
}
