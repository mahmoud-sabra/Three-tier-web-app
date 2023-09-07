provider "aws" {
  region = local.region
}

data "aws_availability_zones" "available" {}

locals {

  region   = "eu-central-1"
  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)
}

################################################################################
# VPC Module
################################################################################

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name   = "my3tiervpc"
  cidr   = local.vpc_cidr

  azs = local.azs

  public_subnets   = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  private_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 3)]
  database_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 6)]

  single_nat_gateway      = true
  enable_nat_gateway      = true
  map_public_ip_on_launch = true


}

resource "aws_key_pair" "instance_key" {
  key_name   = "DevOps-key"
  public_key = file("~/.ssh/id_rsa.pub")
}


resource "aws_instance" "my_instance" {
  ami                    = "ami-0aa74281da945b6b5"
  instance_type          = "t2.micro"
  count                  = 3
  subnet_id              = module.vpc.private_subnets[count.index]
  key_name               = aws_key_pair.instance_key.key_name
  vpc_security_group_ids = [aws_security_group.instance-sg.id]

}
resource "aws_instance" "bastion_instance" {
  ami                    = "ami-0aa74281da945b6b5"
  instance_type          = "t2.micro"
  count                  = 3
  subnet_id              = module.vpc.public_subnets[count.index]
  key_name               = aws_key_pair.instance_key.key_name
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]

}
resource "aws_db_subnet_group" "ACS-rds" {
  name       = "acs-rds"
  subnet_ids = module.vpc.database_subnets

  tags = {
    Name = "ACS-rds"
  }
}

# create the RDS instance with the subnets group
resource "aws_db_instance" "ACS-rds" {
  count = 3
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "8.0.28"
  instance_class         = "db.t3.micro"
  db_name                = "sabradb"
  username               = var.master-username
  password               = var.master-password
  db_subnet_group_name   = aws_db_subnet_group.ACS-rds.name
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.datalayer-sg.id]
  multi_az               = "true"
}