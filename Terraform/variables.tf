variable "aws_region" {
  description = "La región donde se creará el clúster"
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "El nombre del clúster EKS"
  default     = "alfresco-cluster"
}

variable "role" {
  description = "ARN del rol de IAM para EKS"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block para la VPC"
  default     = "192.168.0.0/16"
}