resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-subnet-group"
  subnet_ids = var.subnet_groups # RDS가 위치할 서브넷 ID 입력
}

resource "aws_kms_key" "this" {
  description = "${var.name} KMS Key"
}

resource "aws_db_instance" "this" {
  db_subnet_group_name = aws_db_subnet_group.this.name

  allocated_storage    = 10
  db_name              = var.name # testdb
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  username             = var.username # admin
  # Secret manager 사용하려면 해당 옵션이 없어야함.
  # password             = var.password # password!
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
  vpc_security_group_ids = var.sg

  # 퍼블릭 엑세스 추가
  # publicly_accessible = true

  # Secret manager -> 비밀번호를 직접 설정 여부 옵션
  manage_master_user_password = true

  # KMS 
  master_user_secret_kms_key_id = aws_kms_key.this.key_id

  # multi_az 인스턴스 기능
  multi_az = true

  # 인증서 옵션
  ca_cert_identifier = "rds-ca-rsa4096-g1"

  tags = var.tags
}

resource "aws_secretsmanager_secret" "this" {
  # Secrets Manager에서 사용할 비밀 정보 이름 삭제하는데 7-30일 걸림;
  name_prefix = "${var.name}_" 

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id     = aws_secretsmanager_secret.this.id
  secret_string = jsonencode({
    username = aws_db_instance.this.username,
    password = aws_db_instance.this.password,
    host     = aws_db_instance.this.endpoint,
    dbname   = aws_db_instance.this.db_name,
    port   = aws_db_instance.this.port,
  })
}

# EC2 인스턴스에서 사용할 IAM 역할을 생성합니다.
resource "aws_iam_role" "accessible_ec2_role" {
  name = "${var.name}_accessible_ec2_role"  # IAM 역할 이름

  # EC2 인스턴스에서 해당 역할을 사용할 수 있도록 AssumeRole 정책을 설정합니다.
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action    = "sts:AssumeRole"
    }]
  })
}

# IAM 정책을 생성하여 Secrets Manager에 액세스할 수 있는 권한을 설정합니다.
resource "aws_iam_policy" "secrets_manager_policy" {
  name        = "${var.name}_secrets_manager_policy"  # 정책 이름
  description = "Policy for accessing Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret",
      ],
      Resource = aws_secretsmanager_secret.this.arn,
    }]
  })
}

# IAM 정책을 IAM 역할에 연결합니다.
resource "aws_iam_role_policy_attachment" "secrets_manager_attachment" {
  role       = aws_iam_role.accessible_ec2_role.name
  policy_arn = aws_iam_policy.secrets_manager_policy.arn
}

# 인스턴스 프로파일은 EC2 인스턴스가 IAM 역할에 대한 접근 권한을 받을 수 있도록 해줍니다
resource "aws_iam_instance_profile" "this" {
  name = "${var.name}_secrets_manager_policy"
  role = aws_iam_role.accessible_ec2_role.name
}