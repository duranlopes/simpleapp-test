output "vpc_id" {
  description = "Floci VPC ID."
  value       = aws_vpc.this.id
}

output "subnet_ids" {
  description = "Floci subnet IDs."
  value       = aws_subnet.private[*].id
}

output "security_group_id" {
  description = "Floci EKS security group ID."
  value       = aws_security_group.cluster.id
}
