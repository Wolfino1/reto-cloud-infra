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

  app_prefix      = var.app_prefix
  api_domain_name = var.api_domain_name
  api_origin_path = var.api_origin_path

  frontend_bucket_id  = module.s3.frontend_bucket_id
  frontend_bucket_arn = module.s3.frontend_bucket_arn
}