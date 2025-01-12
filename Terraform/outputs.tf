output "Mongo_id" {
  description = "The ID of the APP instance"
  value       = aws_instance.mongodb.id
}

output "Mongo_Private_IP" {
  description = "The Private IP Address of the MongoDB instance"
  value       = aws_instance.mongodb.private_ip
}
output "Mongo_Public_IP" {
  description = "The IP Address of the MongoDB instance"
  value       = aws_instance.mongodb.public_ip
}
output "App1_id" {
  description = "The ID of the APP instances"
  value       = aws_instance.App[*].id
}
output "App_Private_IP" {
  description = "The IP Address of the MongoDB instance"
  value       = aws_instance.App[*].private_ip
}
output "App_Public_IP" {
  description = "The Public IP Address of the MongoDB instance"
  value       = aws_instance.App[*].public_ip
}

output "SecGroup_Internal_ID" {
  description = "The Security Group ID of the internal servers"
  value       = module.security_group.security_group_id
}
output "SecGroup_LoadBalancer_ID" {
  description = "The Security Group ID of the Load Balancer (External) "
  value       = aws_security_group.alb_sg.id
}

output "lb_dns_name" {
  description = "The DNS name of the Load Balancer"
  value       = aws_lb.app_alb.dns_name
}

