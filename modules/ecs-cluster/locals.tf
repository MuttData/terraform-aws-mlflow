locals {
  service_port                    = 80
  load_balancer_security_group_id = var.load_balancer_external_security_group_id != null ? var.load_balancer_external_security_group_id : aws_security_group.lb.0.id
  ecs_security_group_id           = var.ecs_external_security_group_id != null ? var.ecs_external_security_group_id : aws_security_group.ecs_service.0.id
  ecs_execution_role_name         = var.create_iam_roles ? aws_iam_role.ecs_execution.0.name : var.ecs_execution_role_name
  ecs_execution_role_arn          = var.create_iam_roles ? aws_iam_role.ecs_execution.0.arn : var.ecs_execution_role_arn
  ecs_task_role_name              = var.create_iam_roles ? aws_iam_role.ecs_task.0.name : var.ecs_task_role_name
  ecs_task_role_arn               = var.create_iam_roles ? aws_iam_role.ecs_task.0.arn : var.ecs_task_role_arn
  db_port                         = var.database_port
  db_password_arn                 = var.database_password_secret_is_parameter_store ? data.aws_ssm_parameter.db_password.0.arn : data.aws_secretsmanager_secret.db_password.0.arn
  db_password_value               = var.database_password_secret_is_parameter_store ? data.aws_ssm_parameter.db_password.0.value : data.aws_secretsmanager_secret_version.db_password.0.secret_string
}
