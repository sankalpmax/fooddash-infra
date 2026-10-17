## Production Infrastructure Outputs ##

output "vpc_id" {
  description = "Production VPC ID"
  value       = aws_vpc.prod_vpc.id
}

output "alb_dns_name" {
  description = "Production ALB DNS name"
  value       = aws_lb.prod_alb.dns_name
}

output "rds_endpoint" {
  description = "Production RDS endpoint"
  value       = aws_db_instance.prod_rds.endpoint
}

output "rds_address" {
  description = "Production RDS address"
  value       = aws_db_instance.prod_rds.address
}

output "nat_gateway_ip" {
  description = "Production NAT Gateway public IP"
  value       = aws_eip.prod_nat_eip.public_ip
}
