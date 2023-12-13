resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-subnet-group"
  subnet_ids = var.subnet_groups # RDS가 위치할 서브넷 ID 입력
}

resource "aws_db_instance" "this" {
  db_subnet_group_name = aws_db_subnet_group.this.name

  allocated_storage    = 10
  db_name              = var.name # testdb
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  username             = var.username # admin
  password             = var.password # password!
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
  vpc_security_group_ids = var.sg

  // 퍼블릭 엑세스 추가
  publicly_accessible = true

  tags = var.tags
}

resource "aws_secretsmanager_secret" "DatabaseCredentials" {
  name = "DatabaseCredentials" # Secrets Manager에서 사용할 비밀 정보 이름
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id     = aws_secretsmanager_secret.DatabaseCredentials.id
  secret_string = jsonencode({
    username = aws_db_instance.this.username,
    password = aws_db_instance.this.password,
    host     = aws_db_instance.this.endpoint,
    dbname   = aws_db_instance.this.db_name,
    port   = aws_db_instance.this.port,
  })
}