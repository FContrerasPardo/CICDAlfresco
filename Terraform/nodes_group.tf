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
    desired_size = 3
    max_size     = 3
    min_size     = 3
  }
  remote_access {
    ec2_ssh_key = var.ssh_key_name
    source_security_group_ids = [aws_security_group.alfresco_cluster_sg.id]
  }
  capacity_type  = "SPOT"
  instance_types = ["t3.xlarge"]

  depends_on = [
    aws_eks_cluster.alfresco_cluster,
    aws_security_group.alfresco_cluster_sg
  ]

  tags = {
    Name = "Alfresco-NodeGroup"
  }
}


