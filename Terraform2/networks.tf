module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.14.2"  # Especifica la versión del módulo

  name = var.vpc_name
  cidr = "192.168.0.0/16"

  # Zonas de disponibilidad y subnets
  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["192.168.1.0/24", "192.168.2.0/24", "192.168.3.0/24"]
  public_subnets  = ["192.168.4.0/24", "192.168.5.0/24", "192.168.6.0/24"]

  # Configuración de NAT Gateway e Internet Gateway
  create_igw           = true
  enable_nat_gateway    = true
  single_nat_gateway    = true

  # Etiquetas
  tags = {
    Terraform  = "true"
    Environment = "dev"
  }
}