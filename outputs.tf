output "load_balancer_arn" {
  value = var.launch_in_existing_cluster ? null : module.ecs_cluster.0.load_balancer_arn
}

output "load_balancer_target_group_id" {
  value = var.launch_in_existing_cluster ? null : module.ecs_cluster.0.load_balancer_target_group_id
}

output "load_balancer_target_group_arn" {
  value = var.launch_in_existing_cluster ? null : module.ecs_cluster.0.aws_lb_target_group_arn
}

output "load_balancer_zone_id" {
  value = var.launch_in_existing_cluster ? null : module.ecs_cluster.0.load_balancer_zone_id
}

output "load_balancer_listener_arn" {
  value = var.launch_in_existing_cluster ? null : module.ecs_cluster.0.aws_lb_listener_arn
}

output "load_balancer_dns_name" {
  value = var.launch_in_existing_cluster ? null : module.ecs_cluster.0.load_balancer_dns_name
}

output "cluster_id" {
  value = var.launch_in_existing_cluster ? var.existing_cluster_id : module.ecs_cluster.0.ecs_cluster_id
}

output "ecs_security_group_id" {
  value = local.ecs_security_group_id
}

output "capacity_provider_name" {
  value = var.launch_in_existing_cluster ? var.existing_capacity_provider_name : module.ecs_cluster.0.capacity_provider_name
}

output "service_execution_role_id" {
  value = var.launch_in_existing_cluster ? var.existing_service_execution_role_id : module.ecs_cluster.0.service_execution_role_id
}

output "service_task_role_id" {
  value = var.launch_in_existing_cluster ? var.existing_service_task_role_id : module.ecs_cluster.0.service_task_role_id
}

output "service_autoscaling_target_service_namespace" {
  value = length(aws_appautoscaling_target.mlflow) > 0 ? aws_appautoscaling_target.mlflow.0.service_namespace : null
}

output "service_autoscaling_target_resource_id" {
  value = length(aws_appautoscaling_target.mlflow) > 0 ? aws_appautoscaling_target.mlflow.0.resource_id : null
}

output "service_autoscaling_target_scalable_dimension" {
  value = length(aws_appautoscaling_target.mlflow) > 0 ? aws_appautoscaling_target.mlflow.0.scalable_dimension : null
}

output "service_autoscaling_target_min_capacity" {
  value = length(aws_appautoscaling_target.mlflow) > 0 ? aws_appautoscaling_target.mlflow.0.min_capacity : null
}

output "service_autoscaling_target_max_capacity" {
  value = length(aws_appautoscaling_target.mlflow) > 0 ? aws_appautoscaling_target.mlflow.0.max_capacity : null
}

output "artifact_bucket_id" {
  value = local.artifact_bucket_id
}

output "db_backend_store_username" {
  value = var.launch_in_existing_cluster ? null : module.ecs_cluster.0.db_backend_store_username
}
output "db_backend_store_address" {
  value = var.launch_in_existing_cluster ? null : module.ecs_cluster.0.db_backend_store_address
}
output "db_backend_store_port" {
  value = var.launch_in_existing_cluster ? null : module.ecs_cluster.0.db_backend_store_port
}
output "db_backend_store_name" {
  value = var.launch_in_existing_cluster ? null : module.ecs_cluster.0.db_backend_store_name
}
