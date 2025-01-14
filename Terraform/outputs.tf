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

output "efs_id" {
  value = aws_efs_file_system.alfresco_efs.id
}

output "efs_dns_name" {
  value = aws_efs_file_system.alfresco_efs.dns_name
}

output "efs_mount_targets" {
  value = [
    aws_efs_mount_target.alfresco_efs_target_private_1.id,
    aws_efs_mount_target.alfresco_efs_target_private_2.id
  ]
}

output "efs_storage_class_name" {
  value = kubernetes_storage_class.efs_storage_class.metadata[0].name
}

output "efs_persistent_volume_claim" {
  value = kubernetes_persistent_volume_claim.efs_pvc.metadata[0].name
}

output "node_group_name" {
  value = aws_eks_node_group.alfresco_node_group.node_group_name
}