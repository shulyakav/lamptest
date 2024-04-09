output "db_sg_id" {
  value = aws_security_group.db_sg.id
}

output "db_instance_private_ip" {
  value = aws_instance.db.private_ip
}