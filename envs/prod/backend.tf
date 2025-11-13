terraform {
  backend "s3" {
    bucket         = "prod-tienda-tfstate-173230496266"
    key            = "envs/prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "prod-tienda-tf-locks"
    encrypt        = true
  }
}
