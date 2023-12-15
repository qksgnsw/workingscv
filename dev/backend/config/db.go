package config

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"os"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/secretsmanager"
	_ "github.com/go-sql-driver/mysql"
)

var DB *sql.DB

func init() {
	var connStr string
	var err error

	if os.Getenv("ENV") == "prod" {
		region := "ap-northeast-2"
		secretName := os.Getenv("SECRET_NAME")

		if secretName == "" {
			panic("Require SECRET_NAME.")
		}

		cfg, err := config.LoadDefaultConfig(context.TODO(),
			config.WithRegion(region),
		)
		if err != nil {
			log.Fatal(err)
		}

		// AWS Secrets Manager 클라이언트 생성
		secretsManagerClient := secretsmanager.NewFromConfig(cfg)

		// Secrets Manager에서 비밀 정보 가져오기
		secretString, err := getSecret(secretsManagerClient, secretName)
		if err != nil {
			log.Fatal(err)
		}

		// 비밀 정보에서 데이터베이스 연결 정보 추출
		dbUser := secretString["username"]
		dbPassword := secretString["password"]
		dbHost := secretString["host"]
		dbName := secretString["dbname"]

		// 데이터베이스 연결 문자열 생성
		connStr = fmt.Sprintf("%s:%s@tcp(%s)/%s", dbUser, dbPassword, dbHost, dbName)
	} else {
		dbUser := "admin"         // 사용자 이름
		dbPassword := "password!" // 비밀번호
		dbPort := "3306"          // 포트
		dbName := "testdb"        // 데이터베이스 이름
		dbHost := "localhost"     // 호스트

		// 데이터베이스 연결 문자열 생성
		connStr = fmt.Sprintf("%s:%s@tcp(%s:%s)/%s", dbUser, dbPassword, dbHost, dbPort, dbName)
	}

	fmt.Println(connStr)

	// 데이터베이스에 연결
	DB, err = sql.Open("mysql", connStr)
	if err != nil {
		log.Fatal(err)
	}

	// 데이터베이스 연결 테스트
	err = DB.Ping()
	if err != nil {
		log.Fatal(err)
	}

	// IF NOT EXISTS는 테이블이 이미 존재하는 경우에는 생성하지 않도록 하는 옵션입니다.
	createTableQuery := `
        CREATE TABLE IF NOT EXISTS memos (
            id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
            title VARCHAR(100) NOT NULL,
            content VARCHAR(100) NOT NULL
        )
    `
	_, err = DB.Exec(createTableQuery)
	if err != nil {
		panic(err.Error())
	}

	fmt.Println("Connected to the database.")
}

// AWS Secrets Manager에서 비밀 정보 가져오는 함수
func getSecret(client *secretsmanager.Client, secretName string) (map[string]interface{}, error) {
	input := &secretsmanager.GetSecretValueInput{
		SecretId:     &secretName,
		VersionStage: aws.String("AWSCURRENT"),
	}

	result, err := client.GetSecretValue(context.TODO(), input)
	if err != nil {
		return nil, err
	}

	// 비밀 정보 파싱
	var secretString map[string]interface{}
	if err := json.Unmarshal([]byte(*result.SecretString), &secretString); err != nil {
		return nil, err
	}

	return secretString, nil
}
