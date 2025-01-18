terraform {
  backend "s3" {
    bucket = var.terraform_bucket_name
    key    = "terraform/terraform.tfstate"
    region = var.aws_region
    encrypt = true
  }
}

provider "aws" {
  region                   = var.aws_region
  shared_credentials_files = ["$HOME/.aws/credentials"]
}

# Definición del Clúster EKS usando las subnets y VPC creadas en network.tf
resource "aws_eks_cluster" "alfresco_cluster" {
  name     = var.cluster_name
  role_arn = var.cluster_service_role_arn

  vpc_config {
    subnet_ids = [
      aws_subnet.alfresco_public_subnet_1.id,
      aws_subnet.alfresco_public_subnet_2.id,
      aws_subnet.alfresco_private_subnet_1.id,
      aws_subnet.alfresco_private_subnet_2.id
    ]
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  depends_on = [
    aws_vpc.alfresco_vpc,
    aws_subnet.alfresco_public_subnet_1,
    aws_subnet.alfresco_public_subnet_2,
    aws_subnet.alfresco_private_subnet_1,
    aws_subnet.alfresco_private_subnet_2
  ]

  tags = {
    Name = "Alfresco-EKS-Cluster"
  }
}

# Extrae información del clúster EKS
data "aws_eks_cluster" "cluster" {
  name = aws_eks_cluster.alfresco_cluster.name
}

data "aws_eks_cluster_auth" "cluster" {
  name = aws_eks_cluster.alfresco_cluster.name
}

# Configura el proveedor Kubernetes
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}