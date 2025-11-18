data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "tienda" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "${var.app_prefix}-vpc" }
}

# Subnets privadas
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.tienda.id
  cidr_block        = var.priv_subnet_az1
  availability_zone = data.aws_availability_zones.available.names[0]
  tags              = { Name = "${var.app_prefix}-private-a" }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.tienda.id
  cidr_block        = var.priv_subnet_az2
  availability_zone = data.aws_availability_zones.available.names[1]
  tags              = { Name = "${var.app_prefix}-private-b" }
}

# Internet Gateway + tabla de rutas públicas
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.tienda.id
  tags   = { Name = "${var.app_prefix}-igw" }
}


# Tabla de rutas privada (sin NAT)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.tienda.id
  tags   = { Name = "${var.app_prefix}-rt-private" }
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}
