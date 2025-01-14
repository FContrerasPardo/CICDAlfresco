# Grupo de seguridad para EFS
resource "aws_security_group" "sg_efs_alfresco" {
  vpc_id      = aws_vpc.alfresco_vpc.id
  description = "Security group for Alfresco EFS"
  
  tags = {
    Name = "Alfresco EFS Security Group"
  }
}

# Grupo de seguridad para los nodos del clúster
resource "aws_security_group" "alfresco_cluster_sg" {
  vpc_id      = aws_vpc.alfresco_vpc.id
  description = "Security group for Alfresco EKS Cluster"

  tags = {
    Name = "Alfresco Cluster Security Group"
  }
}

# Regla: Permitir tráfico NFS (2049) del clúster hacia el EFS
resource "aws_security_group_rule" "allow_efs_nfs_from_cluster" {
  type                     = "ingress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  security_group_id        = aws_security_group.sg_efs_alfresco.id
  source_security_group_id = aws_security_group.alfresco_cluster_sg.id
  description              = "Allow NFS from Cluster Nodes to EFS"
}

# Regla: Permitir tráfico interno entre nodos
resource "aws_security_group_rule" "allow_internal_cluster_traffic" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  security_group_id = aws_security_group.alfresco_cluster_sg.id
  self              = true
  description       = "Allow all internal traffic between cluster nodes"
}

# Regla: Permitir salida completa para nodos
resource "aws_security_group_rule" "allow_egress_all_cluster" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.alfresco_cluster_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound traffic from cluster nodes"
}