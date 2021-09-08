locals {
  service_port                       = 80
  mlflow_port                        = var.service_use_nginx_basic_auth ? 5000 : local.service_port
  create_dedicated_bucket            = var.artifact_bucket_id == null
  artifact_bucket_id                 = local.create_dedicated_bucket ? aws_s3_bucket.default.0.id : var.artifact_bucket_id
  ecs_execution_role_name            = var.launch_in_existing_cluster ? var.ecs_execution_role_name : module.ecs_cluster.0.ecs_execution_role_name
  ecs_task_role_name                 = var.launch_in_existing_cluster ? var.ecs_task_role_name : module.ecs_cluster.0.ecs_task_role_name
  ecs_execution_role_arn             = var.launch_in_existing_cluster ? data.aws_iam_role.ecs_execution_role.arn : module.ecs_cluster.0.ecs_execution_role_arn
  ecs_task_role_arn                  = var.launch_in_existing_cluster ? data.aws_iam_role.ecs_task_role.arn : module.ecs_cluster.0.ecs_task_role_arn
  ecs_security_group_id              = var.launch_in_existing_cluster ? var.ecs_external_security_group_id : module.ecs_cluster.0.ecs_security_group_id
  cloudwatch_log_group_external_name = var.cloudwatch_log_group_external_name != null ? var.cloudwatch_log_group_external_name : aws_cloudwatch_log_group.mlflow.0.name
  mlflow_backend_store_username      = var.database_use_external ? var.database_external_username : module.ecs_cluster.0.db_backend_store_username
  mlflow_backend_store_endpoint      = var.database_use_external ? var.database_external_host : module.ecs_cluster.0.db_backend_store_address
  mlflow_backend_store_port          = var.database_use_external ? var.database_external_port : module.ecs_cluster.0.db_backend_store_port
  mlflow_backend_store_name          = var.database_use_external ? var.database_external_name : module.ecs_cluster.0.db_backend_store_name
  db_password_arn                    = var.database_password_secret_is_parameter_store ? data.aws_ssm_parameter.db_password.0.arn : data.aws_secretsmanager_secret.db_password.0.arn
  tags = merge(
    {
      "terraform-module" = "glovo/mlflow/aws"
    },
    var.tags
  )
}

