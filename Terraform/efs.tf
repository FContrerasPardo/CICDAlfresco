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
