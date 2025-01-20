terraform {
  backend "s3" {
    bucket  = "tfm-terraform"
    key     = "eks/terraform.tfstate"
    region  = "us-east-1"
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

## Agrego addons necesarios
#resource "aws_eks_addon" "coredns" {
  cluster_name      = aws_eks_cluster.alfresco_cluster.name
  addon_name        = "coredns"
  resolve_conflicts_on_create = "OVERWRITE"

  tags = {
    Name = "EKS-CoreDNS"
  }
#}
#
#resource "aws_eks_addon" "kube_proxy" {
  cluster_name      = aws_eks_cluster.alfresco_cluster.name
  addon_name        = "kube-proxy"
  resolve_conflicts_on_create = "OVERWRITE"

  tags = {
    Name = "EKS-KubeProxy"
  }
#}
#
#resource "aws_eks_addon" "vpc_cni" {
  cluster_name      = aws_eks_cluster.alfresco_cluster.name
  addon_name        = "vpc-cni"
  resolve_conflicts_on_create = "OVERWRITE"

  tags = {
    Name = "EKS-VPCCNI"
  }
#}
#resource "aws_eks_addon" "efs_csi" {
  cluster_name = aws_eks_cluster.alfresco_cluster.name
  addon_name   = "aws-efs-csi-driver"
  resolve_conflicts_on_create = "OVERWRITE"

  tags = {
    Name = "EFS-CSI-Addon"
  }
#}
#
#resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = jsonencode([
      {
        rolearn  = var.node_role_arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups   = ["system:bootstrappers", "system:nodes"]
      }
    ])

    mapUsers = jsonencode([
      {
        userarn  = data.aws_iam_user.admin.arn
        username = "admin-user"
        groups   = ["system:masters"]
      }
    ])
  }

  depends_on = [aws_eks_cluster.alfresco_cluster]
#}
#
#resource "kubernetes_namespace" "alfresco_namespace" {
#  metadata {
#    name = var.namespace
#  }
#}