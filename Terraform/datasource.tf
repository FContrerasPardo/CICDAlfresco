data "aws_iam_user" "admin" {
  user_name = var.iam_admin_user_name
}