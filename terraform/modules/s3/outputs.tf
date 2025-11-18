output "frontend_bucket" {
  value = aws_s3_bucket.frontend.bucket
}

output "frontend_bucket_id" {
  value = aws_s3_bucket.frontend.id
}

output "frontend_bucket_arn" {
  value = aws_s3_bucket.frontend.arn
}

output "images_bucket" {
  value = aws_s3_bucket.imagenes.bucket
}
