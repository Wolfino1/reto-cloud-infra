output "sg_lambda_id" {
  value = aws_security_group.lambda.id
}

output "sg_rds_id" {
  value = aws_security_group.rds.id
}
