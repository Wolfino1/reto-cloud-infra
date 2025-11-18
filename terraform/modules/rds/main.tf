resource "aws_db_subnet_group" "tienda" {
  name       = "${var.app_prefix}-dbsubnet"
  subnet_ids = var.private_subnet_ids
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
  vpc_security_group_ids   = [var.rds_sg_id]
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
