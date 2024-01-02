provider "aws" {
  region = var.primary_region
}

provider "aws" {
  alias  = "secondary"
  region = var.secondary_region
}

data "aws_caller_identity" "current" {}
data "aws_availability_zones" "primary" {}
data "aws_availability_zones" "secondary" {
  provider = aws.secondary
}

data "aws_ami" "primary_amazon_linux2" {
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

data "aws_ami" "secondary_amazon_linux2" {
  provider = aws.secondary

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
  name             = "workingSCV"
  env              = "Dev"
  primary_region   = var.primary_region
  primary_vpc_cidr = "10.0.0.0/16"
  primary_azs      = slice(data.aws_availability_zones.primary.names, 0, 2)

  secondary_region   = var.secondary_region
  secondary_vpc_cidr = "10.1.0.0/16"
  secondary_azs      = slice(data.aws_availability_zones.secondary.names, 0, 2)

  domain = var.domain

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

module "primary_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name
  cidr = local.primary_vpc_cidr

  azs              = local.primary_azs
  public_subnets   = [for k, v in local.primary_azs : cidrsubnet(local.primary_vpc_cidr, 8, k)]
  private_subnets  = [for k, v in local.primary_azs : cidrsubnet(local.primary_vpc_cidr, 8, k + 100)]
  database_subnets = [for k, v in local.primary_azs : cidrsubnet(local.primary_vpc_cidr, 8, k + 200)]

  enable_nat_gateway = true

  tags = local.tags
}


module "secondary_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  providers = { aws = aws.secondary }

  name = local.name
  cidr = local.secondary_vpc_cidr

  azs              = local.secondary_azs
  public_subnets   = [for k, v in local.secondary_azs : cidrsubnet(local.secondary_vpc_cidr, 8, k)]
  private_subnets  = [for k, v in local.secondary_azs : cidrsubnet(local.secondary_vpc_cidr, 8, k + 100)]
  database_subnets = [for k, v in local.secondary_azs : cidrsubnet(local.secondary_vpc_cidr, 8, k + 200)]

  enable_nat_gateway = true

  tags = local.tags
}

module "primary_certificate" {
  source = "../modules/certificate"

  domain = local.domain
}

module "secondary_certificate" {
  source = "../modules/certificate"

  providers = {
    aws = aws.secondary
  }

  domain = local.domain
}

module "primary_openvpn_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "primary_openvpn_sg"
  description = "This is an primary_openvpn_sg."
  vpc_id      = module.primary_vpc.vpc_id

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
    { Name : "${local.name}-primary_openvpn_sg" },
    local.tags
  )
}

module "secondary_openvpn_sg" {
  source = "terraform-aws-modules/security-group/aws"

  providers = {
    aws = aws.secondary
  }

  name        = "secondary_openvpn_sg"
  description = "This is an secondary_openvpn_sg."
  vpc_id      = module.secondary_vpc.vpc_id

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
    { Name : "${local.name}-secondary_openvpn_sg" },
    local.tags
  )
}

module "primary_openvpnEC2" {
  source = "terraform-aws-modules/ec2-instance/aws"

  count = 2

  ami                         = data.aws_ami.primary_amazon_linux2.id
  subnet_id                   = module.primary_vpc.public_subnets[count.index]
  instance_type               = "t3.micro"
  monitoring                  = true
  associate_public_ip_address = true

  vpc_security_group_ids = [module.primary_openvpn_sg.security_group_id]

  user_data_base64 = base64encode(local.bastion_user_data)

  tags = merge(
    { Name : "${local.name}-primary_openvpnEC2-${count.index}" },
    local.tags
  )
}

module "secondary_openvpnEC2" {
  source = "terraform-aws-modules/ec2-instance/aws"

  providers = {
    aws = aws.secondary
  }

  count = 1

  ami                         = data.aws_ami.secondary_amazon_linux2.id
  subnet_id                   = module.secondary_vpc.public_subnets[count.index]
  instance_type               = "t3.micro"
  monitoring                  = true
  associate_public_ip_address = true

  vpc_security_group_ids = [module.secondary_openvpn_sg.security_group_id]

  user_data_base64 = base64encode(local.bastion_user_data)

  tags = merge(
    { Name : "${local.name}-secondary_openvpnEC2-${count.index}" },
    local.tags
  )
}

module "primary_internal_ec2_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "primary_internal_ec2_sg"
  description = "This is an SG of primary_internal_ec2_sg."
  vpc_id      = module.primary_vpc.vpc_id

  egress_rules = ["all-all"]

  ingress_cidr_blocks = [
    local.primary_vpc_cidr
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
    { Name : "${local.name}-primary_internal_ec2_sg" },
    local.tags
  )
}

module "secondary_internal_ec2_sg" {
  source = "terraform-aws-modules/security-group/aws"

  providers = {
    aws = aws.secondary
  }

  name        = "secondary_internal_ec2_sg"
  description = "This is an SG of secondary_internal_ec2_sg."
  vpc_id      = module.secondary_vpc.vpc_id

  egress_rules = ["all-all"]

  ingress_cidr_blocks = [
    local.secondary_vpc_cidr
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
    { Name : "${local.name}-secondary_internal_ec2_sg" },
    local.tags
  )
}

module "primary_webserver" {
  source = "../modules/autoscalling"

  name = "${local.name}-pri-ws"
  env  = local.env

  min_size         = 2
  max_size         = 4
  desired_capacity = 2

  vpc_id              = module.primary_vpc.vpc_id
  alb_subnets         = [for k, v in module.primary_vpc.public_subnets : v]
  vpc_zone_identifier = [for k, v in module.primary_vpc.private_subnets : v]
  certificate_arn     = module.primary_certificate.arn

  image_id      = data.aws_ami.primary_amazon_linux2.id
  instance_type = "t3.micro"

  // secret manager role 추가
  // 해당 인스턴스들은 RDS 접근이 필요 없음.
  # iam_instance_profile = module.db.role_name

  security_groups = [module.primary_internal_ec2_sg.security_group_id]

  user_data = base64encode(local.web_user_data)

  tags = merge(
    { Name : "${local.name}-primary-webserver" },
    local.tags
  )
}

module "secondary_webserver" {
  source = "../modules/autoscalling"

  providers = {
    aws = aws.secondary
  }

  name = "${local.name}-sec-ws"
  env  = local.env

  min_size         = 1
  max_size         = 2
  desired_capacity = 1

  vpc_id              = module.secondary_vpc.vpc_id
  alb_subnets         = [for k, v in module.secondary_vpc.public_subnets : v]
  vpc_zone_identifier = [for k, v in module.secondary_vpc.private_subnets : v]
  certificate_arn     = module.secondary_certificate.arn

  image_id      = data.aws_ami.secondary_amazon_linux2.id
  instance_type = "t3.micro"

  // secret manager role 추가
  // 해당 인스턴스들은 RDS 접근이 필요 없음.
  # iam_instance_profile = module.db.role_name

  security_groups = [module.secondary_internal_ec2_sg.security_group_id]

  user_data = base64encode(local.web_user_data)

  tags = merge(
    { Name : "${local.name}-secondary-webserver" },
    local.tags
  )
}

module "primary_was" {
  source = "../modules/autoscalling"

  name = "${local.name}-pri-was"
  env  = local.env

  min_size         = 2
  max_size         = 4
  desired_capacity = 2

  vpc_id              = module.primary_vpc.vpc_id
  alb_subnets         = [for k, v in module.primary_vpc.public_subnets : v]
  vpc_zone_identifier = [for k, v in module.primary_vpc.private_subnets : v]
  certificate_arn     = module.primary_certificate.arn

  image_id      = data.aws_ami.primary_amazon_linux2.id
  instance_type = "t3.micro"

  // secret manager role 추가
  # iam_instance_profile = module.db.iam_instance_profile

  security_groups = [module.primary_internal_ec2_sg.security_group_id]

  user_data = base64encode(local.was_user_data)

  tags = merge(
    { Name : "${local.name}-primary-was" },
    local.tags
  )
}

module "secondary_was" {
  source = "../modules/autoscalling"

  providers = {
    aws = aws.secondary
  }

  name = "${local.name}-sec-was"
  env  = local.env

  min_size         = 1
  max_size         = 2
  desired_capacity = 1

  vpc_id              = module.secondary_vpc.vpc_id
  alb_subnets         = [for k, v in module.secondary_vpc.public_subnets : v]
  vpc_zone_identifier = [for k, v in module.secondary_vpc.private_subnets : v]
  certificate_arn     = module.secondary_certificate.arn

  image_id      = data.aws_ami.secondary_amazon_linux2.id
  instance_type = "t3.micro"

  // secret manager role 추가
  # iam_instance_profile = module.db.iam_instance_profile

  security_groups = [module.secondary_internal_ec2_sg.security_group_id]

  user_data = base64encode(local.was_user_data)

  tags = merge(
    { Name : "${local.name}-secondary-was" },
    local.tags
  )
}

module "reg_primary_failover_record" {
  source = "../modules/route"

  domain = local.domain
  type   = "A"

  setSubdomains = [
    {
      subdomain      = "www"
      dns_name       = module.primary_webserver.dns_name
      zone_id        = module.primary_webserver.zone_id
      set_identifier = "primary-www"
    },
    {
      subdomain      = "api"
      dns_name       = module.primary_was.dns_name
      zone_id        = module.primary_was.zone_id
      set_identifier = "primary-api"
    }
  ]
}

module "reg_secondary_failover_record" {
  source = "../modules/route"

  providers = {
    aws = aws.secondary
  }

  domain = local.domain
  type   = "A"

  failover_type = "SECONDARY"

  setSubdomains = [
    {
      subdomain      = "www"
      dns_name       = module.secondary_webserver.dns_name
      zone_id        = module.secondary_webserver.zone_id
      set_identifier = "secondary-www"
    },
    {
      subdomain      = "api"
      dns_name       = module.secondary_was.dns_name
      zone_id        = module.secondary_was.zone_id
      set_identifier = "secondary-api"
    }
  ]
}

# module "internal_db_sg" {
#   source = "terraform-aws-modules/security-group/aws"

#   name        = "internal_db_sg"
#   description = "This is an SG of internal_db_sg."
#   vpc_id      = module.vpc.vpc_id

#   egress_rules = ["all-all"]

#   ingress_cidr_blocks = [
#     local.vpc_cidr,
#     # "0.0.0.0/0" # test
#   ]

#   ingress_with_source_security_group_id = [
#     {
#       rule                     = "mysql-tcp"
#       source_security_group_id = module.internal_ec2_sg.security_group_id
#     }
#   ]

#   ingress_rules = [
#     "all-icmp",
#     "mysql-tcp"
#   ]

#   tags = merge(
#     { Name : "${local.name}-internal_db_sg" },
#     local.tags
#   )
# }

# module "db" {
#   count = local.isPrimary ? 1 : 0
#   source = "../modules/db"

#   name = "testdb"
#   subnet_groups = module.vpc.database_subnets
#   sg            = [module.internal_db_sg.security_group_id]

#   tags = merge(
#     { Name : "${local.name}-db" },
#     local.tags
#   )
# }


output "info" {
  value = {
    primary = {
      webserver = {
        webserver_hoted_name_id = module.primary_webserver.zone_id
        webserver_dns           = module.primary_webserver.dns_name
        webserver_id            = module.primary_webserver.id
      }
      was = {
        was_hoted_name_id = module.primary_was.zone_id
        was_dns           = module.primary_was.dns_name
        was_id            = module.primary_was.id
      }
    }
    secondary = {
      webserver = {
        webserver_hoted_name_id = module.secondary_webserver.zone_id
        webserver_dns           = module.secondary_webserver.dns_name
        webserver_id            = module.secondary_webserver.id
      }
      was = {
        was_hoted_name_id = module.secondary_was.zone_id
        was_dns           = module.secondary_was.dns_name
        was_id            = module.secondary_was.id
      }
    }

    # setup = {
    #   azs = local.azs
    # }

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
