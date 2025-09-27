output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.web_server.id
}

output "public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_eip.web_eip.public_ip
}

output "public_dns" {
  description = "Public DNS of the EC2 instance"
  value       = aws_instance.web_server.public_dns
}

output "website_url" {
  description = "URL to access the website"
  value       = "http://${aws_eip.web_eip.public_ip}"
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.web_sg.id
}

output "instance_state" {
  description = "State of the EC2 instance"
  value       = aws_instance.web_server.instance_state
}