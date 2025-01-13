# AWS Variables:
variable "aws_access_key" {
  type    = string
  description = "AWS Access key"
}
variable "aws_secret_key" {
  type    = string
  description = "AWS Secret key"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
  description = "AWS region"
}

variable "role" {
  description = "Role EKS"
}

variable "cluster_name" {
  description = "nombre del cluster EKS"
}