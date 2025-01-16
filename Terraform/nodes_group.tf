# Grupo de Nodos para el Clúster EKS
resource "aws_eks_node_group" "alfresco_node_group" {
  cluster_name    = aws_eks_cluster.alfresco_cluster.name
  node_group_name = "alfresco-node-group"
  node_role_arn   = var.node_role_arn
  subnet_ids      = [
    aws_subnet.alfresco_private_subnet_1.id,
    aws_subnet.alfresco_private_subnet_2.id
  ]
  scaling_config {
    desired_size = 4
    max_size     = 4
    min_size     = 3
  }

  capacity_type  = "SPOT"
  instance_types = ["m5.xlarge"]

  depends_on = [
    aws_eks_cluster.alfresco_cluster,
    aws_security_group.alfresco_cluster_sg
  ]

  tags = {
    Name = "Alfresco-NodeGroup"
  }
}



# Configuración de Storage Class para EFS en EKS
resource "kubernetes_storage_class" "efs_storage_class" {
  metadata {
    name = "efs-sc"
  }

  storage_provisioner = "efs.csi.aws.com" 
  parameters = {
    fileSystemId  = aws_efs_file_system.alfresco_efs.id
    directoryPerms = "777"
  }

  reclaim_policy       = "Retain"  # Mantener los datos después de eliminar el PVC
  volume_binding_mode  = "Immediate"
}

# Persistent Volume para EFS en EKS
resource "kubernetes_persistent_volume" "efs_pv" {
  metadata {
    name = "efs-pv"
  }

  spec {
    capacity = {
      storage = "5Gi"
    }
    access_modes = ["ReadWriteMany"]
    persistent_volume_source {
      csi {
        driver    = "efs.csi.aws.com"
        volume_handle = aws_efs_file_system.alfresco_efs.id
      }
    }
  }
}

# Persistent Volume Claim para EFS en EKS
resource "kubernetes_persistent_volume_claim" "efs_pvc" {
  metadata {
    name = "efs-pvc"
  }

  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = "5Gi"
      }
    }
    storage_class_name = kubernetes_storage_class.efs_storage_class.metadata[0].name
  }
}

