resource "aws_cloudfront_origin_access_control" "oac_frontend" {
  name                              = "${var.app_prefix}-oac-frontend"
  description                       = "OAC for S3 frontend"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "tienda" {
  enabled             = true
  comment             = "${var.app_prefix}-cdn"
  default_root_object = "index.html"
  price_class         = "PriceClass_100"
  is_ipv6_enabled     = true

  # Origen 1: S3 frontend
  origin {
    domain_name              = "${var.frontend_bucket_id}.s3.amazonaws.com"
    origin_id                = "s3-frontend"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac_frontend.id
  }

  # Origen 2: API Gateway (custom origin), dinámico
  dynamic "origin" {
    for_each = var.api_domain_name != "" ? [1] : []
    content {
      domain_name = var.api_domain_name
      origin_id   = "apigw-origin"
      origin_path = var.api_origin_path

      custom_origin_config {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
  }

  default_cache_behavior {
    target_origin_id       = "s3-frontend"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

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

        cookies {
          forward = "none"
        }
      }

      min_ttl     = 0
      default_ttl = 0
      max_ttl     = 0
    }
  }

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

        cookies {
          forward = "none"
        }
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

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = { Name = "${var.app_prefix}-cdn" }
}

data "aws_iam_policy_document" "frontend_bucket_policy" {
  statement {
    sid       = "AllowCloudFrontRead"
    actions   = ["s3:GetObject"]
    resources = ["${var.frontend_bucket_arn}/*"]

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
  bucket     = var.frontend_bucket_id
  policy     = data.aws_iam_policy_document.frontend_bucket_policy.json
  depends_on = [aws_cloudfront_distribution.tienda]
}
