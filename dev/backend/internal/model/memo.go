package model

import (
	"database/sql"
	"errors"
	"fmt"
	"log"

	"github.com/workingscv/dev/backend/config"
)

type Memo struct {
	ID      int    `json:"id"`
	Title   string `json:"title"`
	Content string `json:"content"`
}

func init() {

	exists, err := HasDataInTable()

	if err != nil {
		log.Fatal(err)
	}

	if !exists {
		memos := []Memo{
			{0, "Captain", "Baek"},
			{0, "Agent1", "Lee"},
			{0, "Agent2", "Ban"},
			{0, "Agent3", "Park"},
			{0, "Agent4", "Kang"},
			{0, "Agent5", "Kim"},
		}

		insertQuery := "INSERT INTO memos (title, content) VALUES (?, ?)"

		for _, v := range memos {
			_, err := config.DB.Exec(insertQuery, v.Title, v.Content)

			if err != nil {
				log.Fatalf("Failed to insert memo: %v", err)
			}
		}

		fmt.Println("Database setup and dummy data insertion successful!")
	}
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

func HasDataInTable() (bool, error) {
	query := "SELECT EXISTS(SELECT 1 FROM memos LIMIT 1)"
	var exists bool
	err := config.DB.QueryRow(query).Scan(&exists)
	if err != nil {
		return false, err
	}
	return exists, nil
}
