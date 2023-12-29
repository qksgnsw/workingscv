provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux2" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# 로컬 변수 선언
locals {
  name     = "workingSCV"
  env      = "Dev"
  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 2)

  domain = var.domain
  isPrimary = var.isPrimary

  bastion_user_data = <<-EOT
  #!/bin/bash
  echo "password!" | passwd --stdin root
  sed -i "s/^#PermitRootLogin yes/PermitRootLogin yes/g" /etc/ssh/sshd_config
  sed -i "s/^PasswordAuthentication no/PasswordAuthentication yes/g" /etc/ssh/sshd_config
  systemctl restart sshd
  EOT

  web_user_data = <<-EOT
  #!/bin/bash
  echo "password!" | passwd --stdin root
  sed -i "s/^#PermitRootLogin yes/PermitRootLogin yes/g" /etc/ssh/sshd_config
  sed -i "s/^PasswordAuthentication no/PasswordAuthentication yes/g" /etc/ssh/sshd_config
  systemctl restart sshd
  yum update -y
  yum install -y httpd.x86_64
  systemctl start httpd.service
  systemctl enable httpd.service
  echo "<h1>Here is Frontend => $(hostname -f)</h1>" > /var/www/html/index.html
  EOT

  was_user_data = <<-EOT
  #!/bin/bash
  echo "password!" | passwd --stdin root
  sed -i "s/^#PermitRootLogin yes/PermitRootLogin yes/g" /etc/ssh/sshd_config
  sed -i "s/^PasswordAuthentication no/PasswordAuthentication yes/g" /etc/ssh/sshd_config
  systemctl restart sshd
  yum update -y
  yum install -y httpd.x86_64
  systemctl start httpd.service
  systemctl enable httpd.service
  echo "<h1>Here is Backend => $(hostname -f)</h1>" > /var/www/html/index.html
  EOT

  tags = {
    Project_Name = local.name
    Env          = local.env
  }
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = local.name
  cidr = local.vpc_cidr

  azs              = local.azs
  public_subnets   = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  private_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 100)]
  database_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 200)]

  enable_nat_gateway = true
  enable_vpn_gateway = false

  tags = merge(
    { Name : "${local.name}-vpc" },
    local.tags
  )
}

module "certificate" {
  source = "./certificate"

  domain = local.domain
}

module "openvpn_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "openvpn_sg"
  description = "This is an openvpn_sg."
  vpc_id      = module.vpc.vpc_id

  egress_rules = [
    "all-icmp",
    "ssh-tcp"
  ]

  ingress_cidr_blocks = ["0.0.0.0/0"]

  ingress_rules = [
    "all-icmp",
    "ssh-tcp"
  ]

  tags = merge(
    { Name : "${local.name}-openvpn_sg" },
    local.tags
  )
}

module "openvpnEC2" {
  source = "terraform-aws-modules/ec2-instance/aws"

  count = 2

  ami                         = data.aws_ami.amazon_linux2.id
  subnet_id                   = module.vpc.public_subnets[count.index]
  instance_type               = "t3.micro"
  monitoring                  = true
  associate_public_ip_address = true

  vpc_security_group_ids = [module.openvpn_sg.security_group_id]

  user_data_base64 = base64encode(local.bastion_user_data)

  tags = merge(
    { Name : "${local.name}-openvpnEC2-${count.index}" },
    local.tags
  )
}

module "internal_ec2_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "internal_ec2_sg"
  description = "This is an SG of internal_ec2_sg."
  vpc_id      = module.vpc.vpc_id

  egress_rules = ["all-all"]

  ingress_cidr_blocks = [
    local.vpc_cidr
    # "0.0.0.0/0" # test
  ]
  ingress_rules = [
    "all-icmp",
    "ssh-tcp",
    "http-80-tcp",
    "https-443-tcp",
    "mysql-tcp"
  ]

  tags = merge(
    { Name : "${local.name}-internal_ec2_sg" },
    local.tags
  )
}

module "webserver" {
  source = "./autoscalling"

  name = "${local.name}-webserver"
  env  = local.env

  min_size             = local.isPrimary ? 2 : 1
  max_size             = local.isPrimary ? 4 : 2
  desired_capacity     = local.isPrimary ? 2 : 1

  vpc_id              = module.vpc.vpc_id
  alb_subnets         = [for k, v in module.vpc.public_subnets : v]
  vpc_zone_identifier = [for k, v in module.vpc.private_subnets : v]
  certificate_arn     = module.certificate.arn

  image_id      = data.aws_ami.amazon_linux2.id
  instance_type = "t3.micro"

  // secret manager role 추가
  // 해당 인스턴스들은 RDS 접근이 필요 없음.
  # iam_instance_profile = module.db.role_name

  security_groups = [module.internal_ec2_sg.security_group_id]

  user_data = base64encode(local.web_user_data)

  tags = merge(
    { Name : "${local.name}-webserver" },
    local.tags
  )
}

module "was" {
  source = "./autoscalling"

  name = "${local.name}-was"
  env  = local.env

  min_size             = local.isPrimary ? 2 : 1
  max_size             = local.isPrimary ? 4 : 2
  desired_capacity     = local.isPrimary ? 2 : 1

  vpc_id              = module.vpc.vpc_id
  alb_subnets         = [for k, v in module.vpc.public_subnets : v]
  vpc_zone_identifier = [for k, v in module.vpc.private_subnets : v]
  certificate_arn     = module.certificate.arn

  image_id      = data.aws_ami.amazon_linux2.id
  instance_type = "t3.micro"

  // secret manager role 추가
  iam_instance_profile = module.db.iam_instance_profile

  security_groups = [module.internal_ec2_sg.security_group_id]

  user_data = base64encode(local.was_user_data)

  tags = merge(
    { Name : "${local.name}-was" },
    local.tags
  )
}

module "regRecords" {
  source = "./route"

  domain = local.domain
  type   = "A"

  setSubdomains = [
    {
      subdomain = "www"
      dns_name  = module.webserver.dns_name
      zone_id   = module.webserver.zone_id
    },
    {
      subdomain = "api"
      dns_name  = module.was.dns_name
      zone_id   = module.was.zone_id
    }
  ]
}

module "internal_db_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "internal_db_sg"
  description = "This is an SG of internal_db_sg."
  vpc_id      = module.vpc.vpc_id

  egress_rules = ["all-all"]

  ingress_cidr_blocks = [
    local.vpc_cidr,
    # "0.0.0.0/0" # test
  ]

  ingress_with_source_security_group_id = [
    {
      rule                     = "mysql-tcp"
      source_security_group_id = module.internal_ec2_sg.security_group_id
    }
  ]

  ingress_rules = [
    "all-icmp",
    "mysql-tcp"
  ]

  tags = merge(
    { Name : "${local.name}-internal_db_sg" },
    local.tags
  )
}

module "db" {
  count = local.isPrimary ? 1 : 0
  source = "./db"

  name = "testdb"
  subnet_groups = module.vpc.database_subnets
  sg            = [module.internal_db_sg.security_group_id]

  tags = merge(
    { Name : "${local.name}-db" },
    local.tags
  )
}


output "info" {
  value = {
    setup = {
      azs = local.azs
    }

    # vpc = {
    #   azs                         = module.vpc.azs,
    #   vpc_cidr_block              = module.vpc.vpc_cidr_block,
    #   private_subnets_cidr_blocks = module.vpc.private_subnets_cidr_blocks,
    #   private_subnets             = module.vpc.private_subnets,
    #   public_subnets_cidr_blocks  = module.vpc.public_subnets_cidr_blocks
    #   public_subnets              = module.vpc.public_subnets
    #   database_subnets            = module.vpc.database_subnets
    # }

    # openvpnEC2 = {
    #   for idx, instance in module.openvpnEC2 : idx => {
    #     ami = instance.ami
    #     az  = instance.availability_zone
    #     id  = instance.id
    #     dns = instance.public_dns
    #   }
    # }

    # webserver = {
    #   dns_name           = module.webserver.dns_name
    #   zone_id            = module.webserver.zone_id
    #   load_balancer_type = module.webserver.load_balancer_type
    #   subnets            = module.webserver.subnets
    #   availability_zones = module.webserver.availability_zones
    #   max_size           = module.webserver.max_size
    #   min_size           = module.webserver.min_size
    # }

    # was = {
    #   dns_name           = module.was.dns_name
    #   zone_id            = module.was.zone_id
    #   load_balancer_type = module.was.load_balancer_type
    #   subnets            = module.was.subnets
    #   availability_zones = module.was.availability_zones
    #   max_size           = module.was.max_size
    #   min_size           = module.was.min_size
    # }

    # db = {
    #   arn       = module.db.arn
    #   domain    = module.db.domain
    #   address   = module.db.address
    #   id        = module.db.id
    #   iam_instance_profile = module.db.iam_instance_profile
    #   secret_name = module.db.secret_name
    # }
  }
}
