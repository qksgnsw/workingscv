package model

import (
    "github.com/workingscv/backend/config"
    "errors"
    "database/sql"
)

type Memo struct {
    ID      int    `json:"id"`
    Title   string `json:"title"`
    Content string `json:"content"`
}

func OneMemo(id int) (Memo, error) {
	memo := Memo{}
	if id == 0 {
		return memo, errors.New("400. Bad Request.")
	}

	row := config.DB.QueryRow("SELECT * FROM memos WHERE id = ?", id)

    err := row.Scan(&memo.ID, &memo.Title, &memo.Content)
    if err != nil {
        if err == sql.ErrNoRows {
            return memo, errors.New("404. Not Found.")
        }
    return memo, err
}

	return memo, nil
}


func InsertMemo(memo Memo) error {
    if memo.Title == "" || memo.Content == "" {
		return errors.New("400. Bad Request. Fields can't be empty.")
	}

    // insert values
	_, err := config.DB.Exec("INSERT INTO memos (title, content) VALUES (?, ?)", memo.Title, memo.Content)
	if err != nil {
		return err
	}

	return nil
}

func UpdateMemo(memo Memo) error {
	if memo.ID == 0 || memo.Title == "" || memo.Content == "" {
		return errors.New("400. Bad Request. Fields can't be empty.")
	}

	// insert values
	_, err := config.DB.Exec("UPDATE memos SET title=?, content=? WHERE id=?;", memo.Title, memo.Content, memo.ID)
	if err != nil {
		return err
	}
	return nil
}

func DeleteMemo(id int) error {
	if id == 0 {
		return errors.New("400. Bad Request.")
	}

	_, err := config.DB.Exec("DELETE FROM memos WHERE id=?;", id)
	if err != nil {
		return errors.New("500. Internal Server Error")
	}

	return nil
}

func AllMemo() ([]Memo, error) {
    rows, err := config.DB.Query("select * from memos")
    if err != nil {
        return nil, err
    }
    defer rows.Close()

    memos := make([]Memo, 0)
    for rows.Next() {
        memo := Memo{}
        err := rows.Scan(&memo.ID, &memo.Title, &memo.Content)
        if err != nil {
            return nil, err
        }   
        memos = append(memos, memo)
    }
    if err = rows.Err(); err != nil {
		return nil, err
	}
	return memos, nil
}