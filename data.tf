data "aws_region" "current" {}

data "aws_secretsmanager_secret" "db_password" {
  count = var.database_password_secret_is_parameter_store ? 0 : 1
  name  = var.database_password_secret_name
}

data "aws_ssm_parameter" "db_password" {
  count = var.database_password_secret_is_parameter_store ? 1 : 0
  name  = var.database_password_secret_name
}
