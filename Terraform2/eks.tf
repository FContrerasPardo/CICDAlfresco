module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.31"

  # Información del clúster
  cluster_name    = var.cluster_name
  cluster_version = "1.31"

  # Red del clúster
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Configuración del endpoint del clúster
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true
  manage_aws_auth_configmap = true
  aws_auth_users = [
    {
    userarn= data.aws_iam_users.admin.arn,
    username= "",
    groups=[
        "",
        ],
    }
  ]
  aws_auth_roles = var.cluster_service_role_arn
  # Configuración de grupos de nodos gestionados
  eks_managed_node_groups = {
    default = {
      desired_capacity = 3
      max_capacity     = 5
      min_capacity     = 1
      instance_types   = ["m5.xlarge"] # Lista de tipos de instancias
      capacity_type    = "SPOT"        # Tipo de capacidad: ON_DEMAND o SPOT
      disk_size        = 20            # Tamaño del disco en GB
      subnets          = module.vpc.private_subnets

      tags = {
        Environment = "dev"
        Name        = "eks-default-node-group"
      }
    }

    additional = {
      desired_capacity = 2
      max_capacity     = 3
      min_capacity     = 1
      instance_types   = ["t3.medium"]
      capacity_type    = "ON_DEMAND"
      disk_size        = 20
      subnets          = module.vpc.private_subnets

      tags = {
        Environment = "dev"
        Name        = "eks-additional-node-group"
      }
    }
  }

  # Etiquetas
  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

data "aws_eks_cluster" "cluster" {
    name = module.eks.cluster_name
}
data "aws_eks_cluster_auth" "cluster" {
    name = module.eks.cluster_name
}
provider "kubernetes" {
    host = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.endpoint.certi)
}