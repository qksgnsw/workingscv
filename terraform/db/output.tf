output "arn" {
    value = aws_db_instance.this.arn
}

output "domain" {
  value = aws_db_instance.this.domain
}

output "address" {
    value = aws_db_instance.this.address
}

output "id" {
    value = aws_db_instance.this.id
}

output "role_name" {
    value = aws_iam_role.accessible_ec2_role.name
}