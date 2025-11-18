variable "app_prefix" {
  type    = string
  default = "prod-tienda"
}

variable "env" {
  type    = string
  default = "prod"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "pub_subnet_az1" {
  type    = string
  default = "10.0.0.0/24"
}

variable "priv_subnet_az1" {
  type    = string
  default = "10.0.1.0/24"
}

variable "pub_subnet_az2" {
  type    = string
  default = "10.0.2.0/24"
}

variable "priv_subnet_az2" {
  type    = string
  default = "10.0.3.0/24"
}

variable "db_user" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_name" {
  type    = string
  default = "tienda"
}

variable "api_domain_name" {
  type    = string
  default = "" # ej: 1vhrh90so6.execute-api.us-east-1.amazonaws.com
}

variable "api_origin_path" {
  type    = string
  default = "/Prod"
}

variable "frontend_bucket_name" {
  type    = string
  default = "prod-tienda-s3-frontend-tf"
}

variable "images_bucket_name" {
  type    = string
  default = "prod-tienda-s3-imagenes-tf"
}
