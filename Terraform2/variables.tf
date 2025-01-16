variable "aws_region" {
  description = "La región donde se creará el clúster"
  default     = "us-east-1"
}

variable "terraform_bucket_name" {
  description = "Nombre del bucket de S3 para almacenar el estado de Terraform"
  default     = "tfm-terraform"
}

variable "cluster_name" {
  description = "El nombre del clúster EKS"
  default     = "alfresco-cluster"
}
variable "vpc_name" {
  description = "El nombre de la vpc"
  default     = "alfresco-VPC"
}


variable "cluster_service_role_arn" {
  description = "ARN del rol IAM de servicio para el cluster de EKS"
  default     = "arn:aws:iam::706722401192:role/eksctl-alfresco-cluster-ServiceRole"
}
variable "node_role_arn" {
  description = "ARN del rol IAM para los nodos del clúster EKS"
  default     = "arn:aws:iam::706722401192:role/eksctl-alfresco-nodegroup"
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

