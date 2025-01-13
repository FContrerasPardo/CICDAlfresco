provider "aws" {
  region = var.aws_region
  shared_credentials_files = ["$HOME/.aws/credentials"]
}

resource "aws_eks_cluster" "alfresco_cluster" {
  name     = var.cluster_name
  role_arn = var.role

  vpc_config {
    subnet_ids = [
      aws_subnet.alfresco_subnet_one.id,
      aws_subnet.alfresco_subnet_two.id,
      aws_subnet.alfresco_subnet_three.id
    ]
  }

  depends_on = [aws_vpc.alfresco_vpc]
}