# Creación del sistema de archivos EFS
resource "aws_efs_file_system" "alfresco_efs" {
  creation_token   = "alfresco-efs"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  tags = {
    Name = "Alfresco EFS"
  }
}

# Mount Target en Subnet Privada 1
resource "aws_efs_mount_target" "alfresco_efs_target_private_1" {
  file_system_id  = aws_efs_file_system.alfresco_efs.id
  subnet_id       = aws_subnet.alfresco_private_subnet_1.id
  security_groups = [aws_security_group.sg_efs_alfresco.id]
}

# Mount Target en Subnet Privada 2
resource "aws_efs_mount_target" "alfresco_efs_target_private_2" {
  file_system_id  = aws_efs_file_system.alfresco_efs.id
  subnet_id       = aws_subnet.alfresco_private_subnet_2.id
  security_groups = [aws_security_group.sg_efs_alfresco.id]
}

# Configuración de Storage Class para EFS en EKS
resource "kubernetes_storage_class" "efs_storage_class" {
  metadata {
    name = "efs-sc"
  }

  storage_provisioner = "efs.csi.aws.com"  # Controlador CSI para AWS EFS
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
    namespace = var.namespace
  }

  spec {
    capacity = {
      storage = "20Gi"
    }
    access_modes = ["ReadWriteMany"]
    persistent_volume_source {
      nfs {
        server = aws_efs_file_system.alfresco_efs.dns_name
        path   = "/"
      }
    }
    storage_class_name = kubernetes_storage_class.efs_storage_class.metadata[0].name
    persistent_volume_reclaim_policy = "Retain"
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
        storage = "20Gi"
      }
    }
    storage_class_name = kubernetes_storage_class.efs_storage_class.metadata[0].name
  }
}
