package config

import (
	"database/sql"
	"fmt"
	// "os"
	_ "github.com/go-sql-driver/mysql"
)

var DB *sql.DB

func init() {
	var err error

	// DB, err = sql.Open("mysql", "root:password@tcp(127.0.0.1:13306)/testdb")
	DB, err = sql.Open("mysql", 
	"admin:password!@tcp(terraform-20231213065039601900000004.cvthkx2gfpla.ap-northeast-2.rds.amazonaws.com:3306)/testdb")
	if err != nil {
		panic(err)
	}

	// 외부 소스로부터 데이터베이스 연결 정보를 가져옵니다.
	// dbType := os.Getenv("DB_TYPE")       // 데이터베이스 유형
	// dbUser := os.Getenv("DB_USER")       // 사용자 이름
	// dbPassword := os.Getenv("DB_PASS")   // 비밀번호
	// dbHost := os.Getenv("DB_HOST")       // 호스트
	// dbPort := os.Getenv("DB_PORT")       // 포트
	// dbName := os.Getenv("DB_NAME")       // 데이터베이스 이름

	// // 데이터베이스 연결 문자열 생성
	// connStr := fmt.Sprintf("%s:%s@tcp(%s:%s)/%s", dbUser, dbPassword, dbHost, dbPort, dbName)

	// // 데이터베이스에 연결
	// DB, err = sql.Open(dbType, connStr)

	if err = DB.Ping(); err != nil {
		panic(err)
	}

	// IF NOT EXISTS는 테이블이 이미 존재하는 경우에는 생성하지 않도록 하는 옵션입니다.
	createTableQuery := `
        CREATE TABLE IF NOT EXISTS memos (
            id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
            title VARCHAR(100) NOT NULL,
            conntent VARCHAR(100) NOT NULL
        )
    `
    _, err = DB.Exec(createTableQuery)
    if err != nil {
        panic(err.Error())
    }

	fmt.Println("Connected to the database.")
}