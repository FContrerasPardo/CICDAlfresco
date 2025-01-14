# Creación del sistema de archivos EFS
resource "aws_efs_file_system" "alfresco_efs" {
  creation_token   = "alfresco-efs"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  tags = {
    Name = "Alfresco EFS"
  }
}

# Grupo de seguridad para EFS con reglas NFS
resource "aws_security_group" "sg_efs_alfresco" {
  vpc_id = aws_vpc.alfresco_vpc.id
  description = "Security group for Alfresco EFS allowing NFS traffic from cluster nodes"

  # Permitir tráfico NFS (puerto 2049) desde las subnets del clúster
  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.alfresco_cluster_sg.id] 
    description     = "Allow NFS traffic from EKS nodes"
  }

  # Salida sin restricciones
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "Alfresco EFS Security Group"
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
