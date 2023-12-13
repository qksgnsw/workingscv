package handler

import (
    "encoding/json"
    "net/http"
    "strconv"

    "github.com/workingscv/backend/internal/model"
)

func Memo(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
        case http.MethodPost:
            createMemo(w, r)
        case http.MethodGet:
            getMemo(w, r)
        case http.MethodPut:
            updateMemo(w, r)
        case http.MethodDelete:
            deleteMemo(w, r)
	}
}

func createMemo(w http.ResponseWriter, r *http.Request) {
    var newMemo model.Memo
    if err := json.NewDecoder(r.Body).Decode(&newMemo); err != nil {
        http.Error(w, err.Error(), http.StatusBadRequest)
        return
    }

    err := model.InsertMemo(newMemo)

    // id, err := h.repo.CreateMemo(newMemo)
    if err != nil {
        http.Error(w, err.Error(), http.StatusInternalServerError)
        return
    }


    w.WriteHeader(http.StatusCreated)
    // w.Write([]byte(strconv.Itoa(id)))
}

func getMemo(w http.ResponseWriter, r *http.Request) {
    id, err := strconv.Atoi(r.URL.Query().Get("id"))
    if err != nil {
        http.Error(w, "Invalid memo ID", http.StatusBadRequest)
        return
    }

    memo, err := model.OneMemo(id)
    if err != nil {
        http.Error(w, err.Error(), http.StatusNotFound)
        return
    }

    jsonResponse, err := json.Marshal(memo)
    if err != nil {
        http.Error(w, err.Error(), http.StatusInternalServerError)
        return
    }

    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(http.StatusOK)
    w.Write(jsonResponse)
}

func updateMemo(w http.ResponseWriter, r *http.Request) {
    var updatedMemo model.Memo
    if err := json.NewDecoder(r.Body).Decode(&updatedMemo); err != nil {
        http.Error(w, err.Error(), http.StatusBadRequest)
        return
    }

    if err := model.UpdateMemo(updatedMemo); err != nil {
        http.Error(w, err.Error(), http.StatusNotFound)
        return
    }

    w.WriteHeader(http.StatusOK)
}

func deleteMemo(w http.ResponseWriter, r *http.Request) {
    id, err := strconv.Atoi(r.URL.Query().Get("id"))
    if err != nil {
        http.Error(w, "Invalid memo ID", http.StatusBadRequest)
        return
    }

    if err := model.DeleteMemo(id); err != nil {
        http.Error(w, err.Error(), http.StatusNotFound)
        return
    }

    w.WriteHeader(http.StatusOK)
}

func GetAllMemos(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
        http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
        return
    }

    // memos := h.repo.GetAllMemos()
    memos, err := model.AllMemo()

    if err != nil {
        http.Error(w, err.Error(), http.StatusInternalServerError)
        return
    }

    jsonResponse, err := json.Marshal(memos)
    if err != nil {
        http.Error(w, err.Error(), http.StatusInternalServerError)
        return
    }

    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(http.StatusOK)
    w.Write(jsonResponse)
}
