resource "aws_eks_node_group" "alfresco_node_group" {
  cluster_name    = aws_eks_cluster.alfresco_cluster.name
  node_group_name = "alfresco-node-group"
  node_role_arn   = var.role
  instance_types  = ["m5.xlarge"]
  capacity_type   = "SPOT"

  scaling_config {
    desired_size = 4
    min_size     = 4
    max_size     = 4
  }

  update_config {
    max_unavailable = 1
  }

  subnet_ids = [
    aws_subnet.alfresco_subnet_one.id,
    aws_subnet.alfresco_subnet_two.id,
    aws_subnet.alfresco_subnet_three.id
  ]

  depends_on = [aws_eks_cluster.alfresco_cluster]
}
