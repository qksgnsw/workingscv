# data "aws_caller_identity" "current" {}

#######################################################################
              # AWS RDS
#######################################################################
# resource "aws_db_subnet_group" "this" {
#   name       = "${var.name}-subnet-group"
#   subnet_ids = var.subnet_groups # RDS가 위치할 서브넷 ID 입력
# }

# resource "aws_kms_key" "this" {
#   description = "${var.name} KMS Key"
# }

# resource "aws_db_instance" "this" {
#   db_subnet_group_name = aws_db_subnet_group.this.name

#   allocated_storage    = 10
#   db_name              = var.name # testdb
#   engine               = "mysql"
#   engine_version       = "5.7"
#   instance_class       = "db.t3.micro"
#   username             = var.username # admin
#   # Secret manager 사용하려면 해당 옵션이 없어야함.
#   password             = var.password # password!
#   parameter_group_name = "default.mysql5.7"
#   skip_final_snapshot  = true
#   vpc_security_group_ids = var.sg

#   multi_az = true # multi_az 인스턴스 기능
  
#   ca_cert_identifier = "rds-ca-rsa4096-g1" # 인증서 옵션

#   auto_minor_version_upgrade = true # 자동 마이너 버전 업그레이드 활성화

#   # 저장 데이터 암호화 활성화 및 KMS 키 설정
#   storage_encrypted = true
#   kms_key_id = aws_kms_key.this.arn # 데이터 암호화
#   backup_retention_period = 1 # 백업 보존 기간을 1일로 설정. read replica 사용시 0보다 커야함
  
#   # publicly_accessible = true # 퍼블릭 엑세스 추가
#   # monitoring_interval = 60 # 향상된 모니터링 활성화
#   # performance_insights_enabled = true # Performance Insights 활성화
#   # manage_master_user_password = true # Secret manager -> 비밀번호를 직접 설정 여부 옵션
#   # master_user_secret_kms_key_id = aws_kms_key.this.key_id # 비밀번호 암호화

#   tags = var.tags
# }

#######################################################################
              # secret manager
#######################################################################

# resource "aws_secretsmanager_secret" "this" {
#   # Secrets Manager에서 사용할 비밀 정보 이름 삭제하는데 7-30일 걸림;
#   name_prefix = "${var.name}_" 

#   tags = var.tags
# }

# resource "aws_secretsmanager_secret_version" "this" {
#   secret_id     = aws_secretsmanager_secret.this.id
#   secret_string = jsonencode({
#     username = aws_db_instance.this.username,
#     password = aws_db_instance.this.password,
#     host     = aws_db_instance.this.endpoint,
#     dbname   = aws_db_instance.this.db_name,
#     port   = aws_db_instance.this.port,
#   })
# }

# # EC2 인스턴스에서 사용할 IAM 역할을 생성합니다.
# resource "aws_iam_role" "accessible_ec2_role" {
#   name = "${var.name}_accessible_ec2_role"  # IAM 역할 이름

#   # EC2 인스턴스에서 해당 역할을 사용할 수 있도록 AssumeRole 정책을 설정합니다.
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [{
#       Effect    = "Allow",
#       Principal = {
#         Service = "ec2.amazonaws.com"
#       },
#       Action    = "sts:AssumeRole"
#     }]
#   })
# }

# # IAM 정책을 생성하여 Secrets Manager에 액세스할 수 있는 권한을 설정합니다.
# resource "aws_iam_policy" "secrets_manager_policy" {
#   name        = "${var.name}_secrets_manager_policy"  # 정책 이름
#   description = "Policy for accessing Secrets Manager"

#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [{
#       Effect   = "Allow",
#       Action   = [
#         "secretsmanager:GetSecretValue",
#         "secretsmanager:DescribeSecret",
#       ],
#       Resource = aws_secretsmanager_secret.this.arn,
#     }]
#   })
# }

# # IAM 정책을 IAM 역할에 연결합니다.
# resource "aws_iam_role_policy_attachment" "secrets_manager_attachment" {
#   role       = aws_iam_role.accessible_ec2_role.name
#   policy_arn = aws_iam_policy.secrets_manager_policy.arn
# }

# # 인스턴스 프로파일은 EC2 인스턴스가 IAM 역할에 대한 접근 권한을 받을 수 있도록 해줍니다
# resource "aws_iam_instance_profile" "this" {
#   name = "${var.name}_secrets_manager_policy"
#   role = aws_iam_role.accessible_ec2_role.name
# }

#######################################################################
              # aurora
#######################################################################

# provider "aws" {
#   alias  = "secondary"
#   region = var.secondary_region
# }
# data "aws_caller_identity" "current" {}

# # resource "aws_rds_global_cluster" "this" {
# #   global_cluster_identifier = var.name
# #   engine                    = "aurora-mysql"
# #   engine_version            = "5.7.mysql_aurora.2.07.5"
# #   database_name             = "example_db"
# #   storage_encrypted         = true
# # }

# resource "aws_rds_global_cluster" "this" {
#   global_cluster_identifier = var.name
#   engine                    = "aurora-postgresql"
#   engine_version            = "14.5"
#   database_name             = "example_db"
#   storage_encrypted         = true
# }

# resource "random_password" "master" {
#   length  = 20
#   special = false
# }

# module "aurora_primary" {
#   source = "terraform-aws-modules/rds-aurora/aws"

#   name                      = var.name
#   database_name             = aws_rds_global_cluster.this.database_name
#   engine                    = aws_rds_global_cluster.this.engine
#   engine_version            = aws_rds_global_cluster.this.engine_version
#   master_username           = "root"
#   global_cluster_identifier = aws_rds_global_cluster.this.id
#   instance_class            = "db.r6g.large"
#   instances                 = { for i in range(2) : i => {} }
#   kms_key_id                = aws_kms_key.primary.arn

#   vpc_id               = var.primary_vpc.vpc_id
#   db_subnet_group_name = var.primary_vpc.database_subnet_group_name
#   security_group_rules = {
#     vpc_ingress = {
#       cidr_blocks = var.primary_vpc_private_subnets_cidr_blocks
#     }
#     egress_example = {
#       cidr_blocks = var.primary_vpc_private_subnets_cidr_blocks
#     }
#   }

#   # Global clusters do not support managed master user password
#   manage_master_user_password = false
#   master_password             = random_password.master.result

#   skip_final_snapshot = true

#   tags = var.tags
# }

# module "aurora_secondary" {
#   source = "terraform-aws-modules/rds-aurora/aws"

#   providers = { aws = aws.secondary }

#   is_primary_cluster = false

#   name                      = var.name
#   engine                    = aws_rds_global_cluster.this.engine
#   engine_version            = aws_rds_global_cluster.this.engine_version
#   global_cluster_identifier = aws_rds_global_cluster.this.id
#   source_region             = var.primary_region
#   instance_class            = "db.r6g.large"
#   instances                 = { for i in range(2) : i => {} }
#   kms_key_id                = aws_kms_key.secondary.arn

#   vpc_id               = var.secondary_vpc.vpc_id
#   db_subnet_group_name = var.secondary_vpc.database_subnet_group_name
#   security_group_rules = {
#     vpc_ingress = {
#       cidr_blocks = var.secondary_vpc_private_subnets_cidr_blocks
#     }
#     egress_example = {
#       cidr_blocks = var.secondary_vpc_private_subnets_cidr_blocks
#     }
#   }

#   # Global clusters do not support managed master user password
#   master_password = random_password.master.result

#   skip_final_snapshot = true

#   depends_on = [
#     module.aurora_primary
#   ]

#   tags = var.tags
# }

# data "aws_iam_policy_document" "rds" {
#   statement {
#     sid       = "Enable IAM User Permissions"
#     actions   = ["kms:*"]
#     resources = ["*"]

#     principals {
#       type = "AWS"
#       identifiers = [
#         "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
#         data.aws_caller_identity.current.arn,
#       ]
#     }
#   }

#   statement {
#     sid = "Allow use of the key"
#     actions = [
#       "kms:Encrypt",
#       "kms:Decrypt",
#       "kms:ReEncrypt*",
#       "kms:GenerateDataKey*",
#       "kms:DescribeKey"
#     ]
#     resources = ["*"]

#     principals {
#       type = "Service"
#       identifiers = [
#         "monitoring.rds.amazonaws.com",
#         "rds.amazonaws.com",
#       ]
#     }
#   }
# }

# resource "aws_kms_key" "primary" {
#   policy = data.aws_iam_policy_document.rds.json
#   tags   = var.tags
# }

# resource "aws_kms_key" "secondary" {
#   provider = aws.secondary

#   policy = data.aws_iam_policy_document.rds.json
#   tags   = var.tags
# }