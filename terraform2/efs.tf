resource "aws_efs_file_system" "alfresco_efs" {
  creation_token = "alfresco-efs"
  performance_mode = "generalPurpose"
  throughput_mode = "bursting"

  tags = {
    Name = "Alfresco EFS"
  }
}

resource "aws_efs_mount_target" "alfresco_efs_target_a" {
  file_system_id  = aws_efs_file_system.alfresco_efs.id
  subnet_id       = aws_subnet.alfresco_subnet_one.id
  security_groups = [aws_security_group.sg_efs_alfresco.id]
}

resource "aws_efs_mount_target" "alfresco_efs_target_b" {
  file_system_id  = aws_efs_file_system.alfresco_efs.id
  subnet_id       = aws_subnet.alfresco_subnet_two.id
  security_groups = [aws_security_group.sg_efs_alfresco.id]
}


