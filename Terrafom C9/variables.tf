variable "aws_region" {
  description = "La región donde se creará el clúster"
  default     = "us-east-1"
}

variable "vpc_cidr_block" {
  description = "CIDR block para la VPC"
  default     = "172.16.0.0/16"
}
