package config

import (
	"database/sql"
	"fmt"
	"os"

	_ "github.com/go-sql-driver/mysql"
)

var DB *sql.DB

func init() {
	var err error

	// 외부 소스로부터 데이터베이스 연결 정보를 가져옵니다.
	// dbType := os.Getenv("DB_TYPE")       // 데이터베이스 유형
	// dbUser := os.Getenv("DB_USER")       // 사용자 이름
	// dbPassword := os.Getenv("DB_PASS")   // 비밀번호
	// dbHost := os.Getenv("DB_HOST")       // 호스트
	// dbPort := os.Getenv("DB_PORT")       // 포트
	// dbName := os.Getenv("DB_NAME")       // 데이터베이스 이름
	dbType := "mysql"              // 데이터베이스 유형
	dbUser := "admin"              // 사용자 이름
	dbPassword := "password!"      // 비밀번호
	dbPort := "3306"               // 포트
	dbName := "testdb"             // 데이터베이스 이름
	dbHost := os.Getenv("DB_HOST") // 호스트

	// 데이터베이스 연결 문자열 생성
	connStr := fmt.Sprintf("%s:%s@tcp(%s:%s)/%s", dbUser, dbPassword, dbHost, dbPort, dbName)

	// 데이터베이스에 연결
	DB, err = sql.Open(dbType, connStr)

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

// Use this code snippet in your app.
// If you need more information about configurations or implementing the sample code, visit the AWS docs:
// https://aws.github.io/aws-sdk-go-v2/docs/getting-started/

// import (
// 	"context"
// 	"log"

// 	"github.com/aws/aws-sdk-go-v2/aws"
// 	"github.com/aws/aws-sdk-go-v2/config"
// 	"github.com/aws/aws-sdk-go-v2/service/secretsmanager"
// )

// func main() {
// 	secretName := "test"
// 	region := "ap-northeast-2"

// 	config, err := config.LoadDefaultConfig(context.TODO(), config.WithRegion(region))
// 	if err != nil {
// 		log.Fatal(err)
// 	}

// 	// Create Secrets Manager client
// 	svc := secretsmanager.NewFromConfig(config)

// 	input := &secretsmanager.GetSecretValueInput{
// 		SecretId:     aws.String(secretName),
// 		VersionStage: aws.String("AWSCURRENT"), // VersionStage defaults to AWSCURRENT if unspecified
// 	}

// 	result, err := svc.GetSecretValue(context.TODO(), input)
// 	if err != nil {
// 		// For a list of exceptions thrown, see
// 		// https://docs.aws.amazon.com/secretsmanager/latest/apireference/API_GetSecretValue.html
// 		log.Fatal(err.Error())
// 	}

// 	// Decrypts secret using the associated KMS key.
// 	var secretString string = *result.SecretString

// 	// Your code goes here.
// }
