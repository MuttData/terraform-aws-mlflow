output "load_balancer_arn" {
  value = length(aws_lb.mlflow) > 0 ? aws_lb.mlflow.0.arn : null
}

output "load_balancer_target_group_id" {
  value = length(aws_lb_target_group.mlflow) > 0 ? aws_lb_target_group.mlflow.0.id : null
}

output "load_balancer_zone_id" {
  value = length(aws_lb.mlflow) > 0 ? aws_lb.mlflow.0.zone_id : null
}

output "load_balancer_dns_name" {
  value = length(aws_lb.mlflow) > 0 ? aws_lb.mlflow.0.dns_name : null
}

output "cluster_id" {
  value = aws_ecs_cluster.mlflow.id
}

output "service_execution_role_id" {
  value = length(aws_iam_role.ecs_execution) > 0 ? aws_iam_role.ecs_execution.0.id : null
}

output "service_task_role_id" {
  value = length(aws_iam_role.ecs_task) > 0 ? aws_iam_role.ecs_task.0.id : null
}

output "service_autoscaling_target_service_namespace" {
  value = aws_appautoscaling_target.mlflow.service_namespace
}

output "service_autoscaling_target_resource_id" {
  value = aws_appautoscaling_target.mlflow.resource_id
}

output "service_autoscaling_target_scalable_dimension" {
  value = aws_appautoscaling_target.mlflow.scalable_dimension
}

output "service_autoscaling_target_min_capacity" {
  value = aws_appautoscaling_target.mlflow.min_capacity
}

output "service_autoscaling_target_max_capacity" {
  value = aws_appautoscaling_target.mlflow.max_capacity
}

output "artifact_bucket_id" {
  value = local.artifact_bucket_id
}
