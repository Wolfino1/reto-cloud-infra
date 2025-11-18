resource "aws_s3_bucket" "frontend" {
  bucket        = var.frontend_bucket_name
  force_destroy = true
  tags          = { Name = var.frontend_bucket_name }
}

resource "aws_s3_bucket_ownership_controls" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
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

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "imagenes" {
  bucket                  = aws_s3_bucket.imagenes.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
