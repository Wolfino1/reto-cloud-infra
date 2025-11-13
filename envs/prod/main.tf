terraform {
  required_providers { aws = { source = "hashicorp/aws", version = "~> 5.0" } }
}

provider "aws" {
  region = "us-east-1"
}


data "aws_availability_zones" "available" {
  state = "available"
}

############################
# VPC + Subnets + Routing
############################
resource "aws_vpc" "tienda" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "${var.app_prefix}-vpc" }
}

# Públicas
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.tienda.id
  cidr_block              = var.pub_subnet_az1
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.app_prefix}-public-a" }
}
resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.tienda.id
  cidr_block              = var.pub_subnet_az2
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.app_prefix}-public-b" }
}

# Privadas
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.tienda.id
  cidr_block        = var.priv_subnet_az1
  availability_zone = data.aws_availability_zones.available.names[0]
  tags              = { Name = "${var.app_prefix}-private-a" }
}
resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.tienda.id
  cidr_block        = var.priv_subnet_az2
  availability_zone = data.aws_availability_zones.available.names[1]
  tags              = { Name = "${var.app_prefix}-private-b" }
}

# IGW + rutas públicas
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.tienda.id
  tags   = { Name = "${var.app_prefix}-igw" }
}
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.tienda.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "${var.app_prefix}-rt-public" }
}
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# RT privada (sin NAT, solo local)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.tienda.id
  tags   = { Name = "${var.app_prefix}-rt-private" }
}
resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}
resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}

############################
# Security Groups
############################
resource "aws_security_group" "rds" {
  name        = "${var.app_prefix}-sg-rds2"
  description = "MySQL 3306 desde SG Lambda"
  vpc_id      = aws_vpc.tienda.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda.id]
    description     = "MySQL desde Lambda"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.app_prefix}-sg-rds2" }
}

resource "aws_security_group" "lambda" {
  name        = "${var.app_prefix}-sg-lambda"
  description = "Lambda egress-only"
  vpc_id      = aws_vpc.tienda.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.app_prefix}-sg-lambda" }
}

############################
# S3 buckets (frontend, imágenes)
############################
resource "aws_s3_bucket" "frontend" {
  bucket        = var.frontend_bucket_name
  force_destroy = true
  tags          = { Name = var.frontend_bucket_name }
}
resource "aws_s3_bucket_ownership_controls" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  rule { object_ownership = "BucketOwnerEnforced" }
}
resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket                  = aws_s3_bucket.frontend.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "imagenes" {
  bucket        = var.images_bucket_name
  force_destroy = true
  tags          = { Name = var.images_bucket_name }
}
resource "aws_s3_bucket_ownership_controls" "imagenes" {
  bucket = aws_s3_bucket.imagenes.id
  rule { object_ownership = "BucketOwnerEnforced" }
}
resource "aws_s3_bucket_public_access_block" "imagenes" {
  bucket                  = aws_s3_bucket.imagenes.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

############################
# RDS (subnet group + instancia MySQL)
############################
resource "aws_db_subnet_group" "tienda" {
  name       = "${var.app_prefix}-dbsubnet"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  tags       = { Name = "${var.app_prefix}-dbsubnet" }
}

resource "aws_db_instance" "tienda" {
  identifier               = "${var.app_prefix}-rds-tf"
  engine                   = "mysql"
  engine_version           = "8.0"
  instance_class           = "db.t3.micro"
  allocated_storage        = 20
  max_allocated_storage    = 100
  db_subnet_group_name     = aws_db_subnet_group.tienda.name
  vpc_security_group_ids   = [aws_security_group.rds.id]
  username                 = var.db_user
  password                 = var.db_password
  db_name                  = var.db_name
  port                     = 3306
  multi_az                 = false
  publicly_accessible      = false
  storage_encrypted        = true
  backup_retention_period  = 1
  delete_automated_backups = true
  skip_final_snapshot      = true
  apply_immediately        = true
  deletion_protection      = false
  tags                     = { Name = "${var.app_prefix}-rds" }
}

############################
# CloudFront + OAC (S3 frontend + API Gateway)
############################
# OAC para S3
resource "aws_cloudfront_origin_access_control" "oac_frontend" {
  name                              = "${var.app_prefix}-oac-frontend"
  description                       = "OAC for S3 frontend"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Distribución
resource "aws_cloudfront_distribution" "tienda" {
  enabled             = true
  comment             = "${var.app_prefix}-cdn"
  default_root_object = "index.html"
  price_class         = "PriceClass_100" # barato
  is_ipv6_enabled     = true

  # Origen 1: S3 frontend (con OAC)
  origin {
    domain_name              = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id                = "s3-frontend"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac_frontend.id
  }

  # Origen 2: API Gateway (custom origin)
  dynamic "origin" {
    for_each = var.api_domain_name != "" ? [1] : []
    content {
      domain_name = var.api_domain_name # ej: 1vhrh90so6.execute-api.us-east-1.amazonaws.com
      origin_id   = "apigw-origin"
      origin_path = var.api_origin_path # ej: /Prod

      custom_origin_config {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
  }

  # Default behavior -> S3 frontend
  default_cache_behavior {
    target_origin_id       = "s3-frontend"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }
  }

  # /products -> API Gateway (GET/HEAD)
  dynamic "ordered_cache_behavior" {
    for_each = var.api_domain_name != "" ? [1] : []
    content {
      path_pattern           = "/products"
      target_origin_id       = "apigw-origin"
      viewer_protocol_policy = "redirect-to-https"
      allowed_methods        = ["GET", "HEAD", "OPTIONS"]
      cached_methods         = ["GET", "HEAD"]
      forwarded_values {
        query_string = false
        cookies { forward = "none" }
      }
      min_ttl     = 0
      default_ttl = 0
      max_ttl     = 0
    }
  }

  # /order -> API Gateway (POST)
  dynamic "ordered_cache_behavior" {
    for_each = var.api_domain_name != "" ? [1] : []
    content {
      path_pattern           = "/order"
      target_origin_id       = "apigw-origin"
      viewer_protocol_policy = "redirect-to-https"
      allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
      cached_methods         = ["GET", "HEAD"]
      forwarded_values {
        query_string = false
        cookies { forward = "none" }
      }
      min_ttl     = 0
      default_ttl = 0
      max_ttl     = 0
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  viewer_certificate { cloudfront_default_certificate = true }

  tags = { Name = "${var.app_prefix}-cdn" }
}

# Bucket policy S3 frontend: solo lectura desde esta distribución via OAC (SourceArn)
data "aws_iam_policy_document" "frontend_bucket_policy" {
  statement {
    sid       = "AllowCloudFrontRead"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.frontend.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.tienda.arn]
    }
  }
}


resource "aws_s3_bucket_policy" "frontend" {
  bucket     = aws_s3_bucket.frontend.id
  policy     = data.aws_iam_policy_document.frontend_bucket_policy.json
  depends_on = [aws_cloudfront_distribution.tienda]
}

# (Opcional) servir imágenes también vía la misma distro:
# Añade otro origin/behavior si quieres mapear, por ejemplo, "/products/*" al bucket de imágenes.

