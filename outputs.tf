output "load_balancer_arn" {
  value = aws_lb.mlflow.arn
}

output "load_balancer_target_group_id" {
  value = aws_lb_target_group.mlflow.id
}

output "load_balancer_zone_id" {
  value = aws_lb.mlflow.zone_id
}

output "load_balancer_dns_name" {
  value = aws_lb.mlflow.dns_name
}

output "cluster_id" {
  value = aws_ecs_cluster.mlflow.id
}

output "capacity_provider_name" {
  value = length(aws_ecs_capacity_provider.mlflow) > 0 ? aws_ecs_capacity_provider.mlflow.0.name : null
}

output "service_execution_role_id" {
  value = length(aws_iam_role.ecs_execution) > 0 ? aws_iam_role.ecs_execution.0.id : null
}

output "service_task_role_id" {
  value = length(aws_iam_role.ecs_task) > 0 ? aws_iam_role.ecs_task.0.id : null
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
