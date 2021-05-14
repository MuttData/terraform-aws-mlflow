locals {
  service_port                       = 80
  db_port                            = var.database_port
  create_dedicated_bucket            = var.artifact_bucket_id == null
  artifact_bucket_id                 = local.create_dedicated_bucket ? aws_s3_bucket.default.0.id : var.artifact_bucket_id
  ecs_execution_role_arn             = var.create_iam_roles ? aws_iam_role.ecs_execution.0.arn : var.ecs_execution_role_arn
  ecs_task_role_arn                  = var.create_iam_roles ? aws_iam_role.ecs_task.0.arn : var.ecs_task_role_arn
  cloudwatch_log_group_external_name = var.cloudwatch_log_group_external_name != null ? var.cloudwatch_log_group_external_name : aws_cloudwatch_log_group.mlflow.0.name
  mlflow_backend_store_username      = var.database_use_external ? var.database_external_username : aws_rds_cluster.backend_store.0.master_username
  mlflow_backend_store_endpoint      = var.database_use_external ? var.database_external_host : aws_rds_cluster.backend_store.0.endpoint
  mlflow_backend_store_port          = var.database_use_external ? var.database_external_port : aws_rds_cluster.backend_store.0.port
  mlflow_backend_store_port_name     = var.database_use_external ? var.database_external_name : aws_rds_cluster.backend_store.0.database_name
  load_balancer_security_group_id    = var.load_balancer_external_security_group_id ? var.load_balancer_external_security_group_id : aws_security_group.lb.0.id
  ecs_security_group_id              = var.ecs_external_security_group_id ? var.ecs_external_security_group_id : aws_security_group.ecs_service.0.id
  db_password_arn                    = var.database_password_secret_is_parameter_store ? data.aws_ssm_parameter.db_password.0.arn : data.aws_secretsmanager_secret.db_password.0.arn
  db_password_value                  = var.database_password_secret_is_parameter_store ? data.aws_ssm_parameter.metadata_rds_db.0.value : data.aws_secretsmanager_secret_version.db_password.0.secret_string
  tags = merge(
    {
      "terraform-module" = "glovo/mlflow/aws"
    },
    var.tags
  )
}

