locals {
  service_port                       = 80
  db_port                            = var.database_port
  create_dedicated_bucket            = var.artifact_bucket_id == null
  artifact_bucket_id                 = local.create_dedicated_bucket ? aws_s3_bucket.default.0.id : var.artifact_bucket_id
  ecs_execution_role_arn             = var.create_iam_roles ? aws_iam_role.ecs_execution.0.arn : var.ecs_execution_role_arn
  ecs_task_role_arn                  = var.create_iam_roles ? aws_iam_role.ecs_task.0.arn : var.ecs_task_role_arn
  cloudwatch_log_group_external_name = var.cloudwatch_log_group_external_name ? var.cloudwatch_log_group_external_name : aws_cloudwatch_log_group.mlflow.arn
  tags = merge(
    {
      "terraform-module" = "glovo/mlflow/aws"
    },
    var.tags
  )
}

