variable "aws_region" {
  description = "La región donde se creará el clúster"
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "El nombre del clúster EKS"
  default     = "alfresco-cluster"
}


variable "node_role_arn" {
  description = "ARN del rol IAM para los nodos del clúster EKS"
}

variable "ssh_key_name" {
  description = "Nombre de la clave SSH para acceder a los nodos"
  default     = "my-eks-key"
}

variable "vpc_cidr_block" {
  description = "CIDR block para la VPC"
  default     = "192.168.0.0/16"
}

variable "efs_name" {
  description = "Nombre del sistema de archivos EFS"
  default     = "alfresco-efs"
}

variable "efs_performance_mode" {
  description = "Modo de rendimiento para EFS"
  default     = "generalPurpose"
}

variable "efs_throughput_mode" {
  description = "Modo de rendimiento del EFS"
  default     = "bursting"
}

