
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

variable "aws_subnet_id" {
  type    = string
  description = "AWS Subnet"
}
variable "aws_vpc_id" {
  type    = string
  description = "AWS vpc Id "
}

variable "aws_pair_key" {
  type    = string
  description = "AWS pair key"
}

variable "aws_instance_type" {
  type    = string
  description = "AWS instance_type"
  default     = "t2.micro"
}