terraform {
  backend "s3" {
    bucket  = "tfm-terraform"
    key     = "eks/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

provider "aws" {
  region                   = var.aws_region
  shared_credentials_files = ["$HOME/.aws/credentials"]
}
