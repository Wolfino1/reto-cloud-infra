output "ready" {
  value = "estructura creada"
}

output "vpc_id" {
  value = aws_vpc.tienda.id
}

output "subnets_publicas" {
  value = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

output "subnets_privadas" {
  value = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}

output "sg_lambda_id" {
  value = aws_security_group.lambda.id
}

output "sg_rds_id" {
  value = aws_security_group.rds.id
}

output "frontend_bucket" {
  value = aws_s3_bucket.frontend.bucket
}

output "imagenes_bucket" {
  value = aws_s3_bucket.imagenes.bucket
}

output "rds_endpoint" {
  value = aws_db_instance.tienda.endpoint
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.tienda.domain_name
}

output "cloudfront_id" {
  value = aws_cloudfront_distribution.tienda.id
}
