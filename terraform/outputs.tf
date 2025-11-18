output "ready" {
  value = "estructura creada"
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "subnets_privadas" {
  value = module.vpc.private_subnets
}

output "sg_lambda_id" {
  value = module.security.sg_lambda_id
}

output "sg_rds_id" {
  value = module.security.sg_rds_id
}

output "frontend_bucket" {
  value = module.s3.frontend_bucket
}

output "imagenes_bucket" {
  value = module.s3.images_bucket
}

output "rds_endpoint" {
  value = module.rds.rds_endpoint
}

output "cloudfront_domain_name" {
  value = module.cloudfront.cloudfront_domain_name
}

output "cloudfront_id" {
  value = module.cloudfront.cloudfront_id
}
