terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Módulo de red (VPC + subnets + rutas)
module "vpc" {
  source = "./modules/vpc"

  app_prefix      = var.app_prefix
  vpc_cidr        = var.vpc_cidr
  pub_subnet_az1  = var.pub_subnet_az1
  pub_subnet_az2  = var.pub_subnet_az2
  priv_subnet_az1 = var.priv_subnet_az1
  priv_subnet_az2 = var.priv_subnet_az2
}

# Módulo de security groups
module "security" {
  source = "./modules/security"

  app_prefix = var.app_prefix
  vpc_id     = module.vpc.vpc_id
}

# Módulo S3 (frontend + imágenes)
module "s3" {
  source = "./modules/s3"

  frontend_bucket_name = var.frontend_bucket_name
  images_bucket_name   = var.images_bucket_name
}

# Módulo RDS
module "rds" {
  source = "./modules/rds"

  app_prefix = var.app_prefix

  db_user     = var.db_user
  db_password = var.db_password
  db_name     = var.db_name

  private_subnet_ids = module.vpc.private_subnets
  rds_sg_id          = module.security.sg_rds_id
}

# Módulo CloudFront + OAC + bucket policy
module "cloudfront" {
  source = "./modules/cloudfront"

  app_prefix       = var.app_prefix
  api_domain_name  = var.api_domain_name
  api_origin_path  = var.api_origin_path

  frontend_bucket_id  = module.s3.frontend_bucket_id
  frontend_bucket_arn = module.s3.frontend_bucket_arn
}

############################
# MOVED: mapear recursos antiguos -> módulos
############################

# VPC + subnets + routing
moved {
  from = aws_vpc.tienda
  to   = module.vpc.aws_vpc.tienda
}

moved {
  from = aws_subnet.public_a
  to   = module.vpc.aws_subnet.public_a
}

moved {
  from = aws_subnet.public_b
  to   = module.vpc.aws_subnet.public_b
}

moved {
  from = aws_subnet.private_a
  to   = module.vpc.aws_subnet.private_a
}

moved {
  from = aws_subnet.private_b
  to   = module.vpc.aws_subnet.private_b
}

moved {
  from = aws_internet_gateway.igw
  to   = module.vpc.aws_internet_gateway.igw
}

moved {
  from = aws_route_table.public
  to   = module.vpc.aws_route_table.public
}

moved {
  from = aws_route_table_association.public_a
  to   = module.vpc.aws_route_table_association.public_a
}

moved {
  from = aws_route_table_association.public_b
  to   = module.vpc.aws_route_table_association.public_b
}

moved {
  from = aws_route_table.private
  to   = module.vpc.aws_route_table.private
}

moved {
  from = aws_route_table_association.private_a
  to   = module.vpc.aws_route_table_association.private_a
}

moved {
  from = aws_route_table_association.private_b
  to   = module.vpc.aws_route_table_association.private_b
}

# Security groups
moved {
  from = aws_security_group.lambda
  to   = module.security.aws_security_group.lambda
}

moved {
  from = aws_security_group.rds
  to   = module.security.aws_security_group.rds
}

# S3 buckets frontend + imágenes
moved {
  from = aws_s3_bucket.frontend
  to   = module.s3.aws_s3_bucket.frontend
}

moved {
  from = aws_s3_bucket_ownership_controls.frontend
  to   = module.s3.aws_s3_bucket_ownership_controls.frontend
}

moved {
  from = aws_s3_bucket_public_access_block.frontend
  to   = module.s3.aws_s3_bucket_public_access_block.frontend
}

moved {
  from = aws_s3_bucket.imagenes
  to   = module.s3.aws_s3_bucket.imagenes
}

moved {
  from = aws_s3_bucket_ownership_controls.imagenes
  to   = module.s3.aws_s3_bucket_ownership_controls.imagenes
}

moved {
  from = aws_s3_bucket_public_access_block.imagenes
  to   = module.s3.aws_s3_bucket_public_access_block.imagenes
}

# RDS
moved {
  from = aws_db_subnet_group.tienda
  to   = module.rds.aws_db_subnet_group.tienda
}

moved {
  from = aws_db_instance.tienda
  to   = module.rds.aws_db_instance.tienda
}

# CloudFront + bucket policy
moved {
  from = aws_cloudfront_origin_access_control.oac_frontend
  to   = module.cloudfront.aws_cloudfront_origin_access_control.oac_frontend
}

moved {
  from = aws_cloudfront_distribution.tienda
  to   = module.cloudfront.aws_cloudfront_distribution.tienda
}

moved {
  from = aws_s3_bucket_policy.frontend
  to   = module.cloudfront.aws_s3_bucket_policy.frontend
}
