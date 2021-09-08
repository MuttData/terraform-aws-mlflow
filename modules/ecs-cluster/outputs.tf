output "aws_lb_listener_arn" {
  value = length(aws_lb_listener.mlflow) > 0 ? aws_lb_listener.mlflow.0.arn : null
}

output "aws_lb_target_group_arn" {
  value = aws_lb_target_group.mlflow.arn
}

output "ecs_cluster_id" {
  value = aws_ecs_cluster.mlflow.id
}

output "ecs_execution_role_name" {
  value = local.ecs_execution_role_name
}

output "ecs_task_role_name" {
  value = local.ecs_task_role_name
}

output "ecs_execution_role_arn" {
  value = local.ecs_execution_role_arn
}

output "ecs_task_role_arn" {
  value = local.ecs_task_role_arn
}

output "ecs_security_group_id" {
  value = local.ecs_security_group_id
}

output "capacity_provider_name" {
  value = var.ecs_launch_type == "EC2" ? aws_ecs_capacity_provider.mlflow.0.name : null
}

output "db_backend_store_username" {
  value = aws_db_instance.backend_store.0.username
}
output "db_backend_store_address" {
  value = aws_db_instance.backend_store.0.address
}
output "db_backend_store_port" {
  value = aws_db_instance.backend_store.0.port
}
output "db_backend_store_name" {
  value = aws_db_instance.backend_store.0.name
}

output "db_password_arn" {
  value = local.db_password_arn
}

output "service_execution_role_id" {
  value = length(aws_iam_role.ecs_execution) > 0 ? aws_iam_role.ecs_execution.0.id : null
}

output "service_task_role_id" {
  value = length(aws_iam_role.ecs_task) > 0 ? aws_iam_role.ecs_task.0.id : null
}

output "load_balancer_arn" {
  value = aws_lb.mlflow.arn
}

output "load_balancer_dns_name" {
  value = aws_lb.mlflow.dns_name
}

output "load_balancer_zone_id" {
  value = aws_lb.mlflow.zone_id
}

output "load_balancer_target_group_id" {
  value = aws_lb_target_group.mlflow.id
}
