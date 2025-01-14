# Security Group para los Nodos del Clúster
resource "aws_security_group" "alfresco_cluster_sg" {
  vpc_id = aws_vpc.alfresco_vpc.id

  description = "Security Group for Alfresco EKS Cluster Nodes"

  # Permitir comunicación entre nodos
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
    description = "Allow all traffic between cluster nodes"
  }

  # Permitir tráfico NFS hacia EFS
  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_efs_alfresco.id]
    description     = "Allow NFS traffic to EFS"
  }

  # Salida sin restricciones
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Alfresco-Cluster-SecurityGroup"
  }
}