output "vpc_id" {
  value = aws_vpc.tienda.id
}

output "private_subnets" {
  value = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}
