output "vpc_id" {
  value = aws_vpc.alfresco_vpc.id
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.alfresco_cluster.endpoint
}

output "eks_cluster_name" {
  value = aws_eks_cluster.alfresco_cluster.name
}

output "subnets" {
  value = [
    aws_subnet.alfresco_public_subnet_1.id,
    aws_subnet.alfresco_public_subnet_2.id,
    aws_subnet.alfresco_private_subnet_1.id,
    aws_subnet.alfresco_private_subnet_2.id
  ]
}
