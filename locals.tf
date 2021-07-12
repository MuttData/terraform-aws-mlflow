locals {
  service_port                       = 80
  db_port                            = var.database_port
  create_dedicated_bucket            = var.artifact_bucket_id == null
  artifact_bucket_id                 = local.create_dedicated_bucket ? aws_s3_bucket.default.0.id : var.artifact_bucket_id
  ecs_execution_role_name            = var.create_iam_roles ? aws_iam_role.ecs_execution.0.name : var.ecs_execution_role_name
  ecs_task_role_name                 = var.create_iam_roles ? aws_iam_role.ecs_task.0.name : var.ecs_task_role_name
  ecs_execution_role_arn             = var.create_iam_roles ? aws_iam_role.ecs_execution.0.arn : data.aws_iam_role.ecs_execution.0.arn
  ecs_task_role_arn                  = var.create_iam_roles ? aws_iam_role.ecs_task.0.arn : data.aws_iam_role.ecs_task.0.arn
  cloudwatch_log_group_external_name = var.cloudwatch_log_group_external_name != null ? var.cloudwatch_log_group_external_name : aws_cloudwatch_log_group.mlflow.0.name
  mlflow_backend_store_username      = var.database_use_external ? var.database_external_username : aws_db_instance.backend_store.0.username
  mlflow_backend_store_endpoint      = var.database_use_external ? var.database_external_host : aws_db_instance.backend_store.0.endpoint
  mlflow_backend_store_port          = var.database_use_external ? var.database_external_port : aws_db_instance.backend_store.0.port
  mlflow_backend_store_port_name     = var.database_use_external ? var.database_external_name : aws_db_instance.backend_store.0.name
  load_balancer_security_group_id    = var.load_balancer_external_security_group_id != null ? var.load_balancer_external_security_group_id : aws_security_group.lb.0.id
  ecs_security_group_id              = var.ecs_external_security_group_id != null ? var.ecs_external_security_group_id : aws_security_group.ecs_service.0.id
  db_password_arn                    = var.database_password_secret_is_parameter_store ? data.aws_ssm_parameter.db_password.0.arn : data.aws_secretsmanager_secret.db_password.0.arn
  db_password_value                  = var.database_password_secret_is_parameter_store ? data.aws_ssm_parameter.db_password.0.value : data.aws_secretsmanager_secret_version.db_password.0.secret_string
  tags = merge(
    {
      "terraform-module" = "glovo/mlflow/aws"
    },
    var.tags
  )
}

