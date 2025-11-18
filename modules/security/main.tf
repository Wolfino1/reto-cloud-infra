resource "aws_security_group" "lambda" {
  name        = "${var.app_prefix}-sg-lambda"
  description = "Lambda egress-only"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.app_prefix}-sg-lambda" }
}

resource "aws_security_group" "rds" {
  name        = "${var.app_prefix}-sg-rds2"
  description = "MySQL 3306 desde SG Lambda"
  vpc_id      = var.vpc_id

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
