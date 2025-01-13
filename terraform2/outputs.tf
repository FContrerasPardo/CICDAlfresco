output "vpc_id" {
  description = "ID de la VPC creada por el clúster EKS"
  value       = aws_vpc.alfresco_vpc.id
}
output "vpc_arn" {
  description = "arn de la VPC creada por el clúster EKS"
  value       = aws_vpc.alfresco_vpc.arn
}
output "efs_arn" {
  description = "arn del sistema de archivos EFS"
  value       = aws_efs_file_system.alfresco_efs.arn
}