resource "aws_security_group" "alfresco_security" {
  name        = "alfresco_security"
  description = "Aceptar todas conexiones"
  vpc_id      = aws_vpc.alfresco_vpc.id

  # Regla para permitir conexiones kubectl desde cualquier dirección IP externa
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Regla para permitir que los servicios internos se vean entre sí
  ingress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.alfresco_security.id]
  }

  # Regla para permitir que los servicios internos se vean entre sí
  egress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.alfresco_security.id]
  }
}

resource "aws_security_group" "sg_efs_alfresco" {
  vpc_id = aws_vpc.alfresco_vpc.id
  description = "Security group for Alfresco EFS allowing NFS access from cluster SG"

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    security_groups = [aws_security_group.alfresco_security.id]
    description = "Allow NFS traffic from the cluster"
  }

  egress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    security_groups = [aws_security_group.alfresco_security.id]
    description = "Allow NFS traffic to the cluster"
  }

  tags = {
    Name = "SG-EFS-Alfresco"
  }
}