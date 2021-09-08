data "aws_iam_role" "ecs_execution_role" {
  name = var.ecs_execution_role_name
}

data "aws_iam_role" "ecs_task_role" {
  name = var.ecs_task_role_name
}

module "ecs_cluster" {
  source = "./modules/ecs-cluster"

  # if we want to launch mlflow in an existing ECS Cluster do not create a new one
  count = var.launch_in_existing_cluster ? 0 : 1

  tags = local.tags

  unique_name      = var.unique_name
  vpc_id           = var.vpc_id
  create_iam_roles = var.create_iam_roles

  ecs_launch_type                = var.ecs_launch_type
  ecs_subnet_ids                 = var.ecs_subnet_ids
  ecs_min_instance_count         = var.ecs_min_instance_count
  ecs_max_instance_count         = var.ecs_max_instance_count
  ecs_external_security_group_id = var.ecs_external_security_group_id
  ecs_execution_role_name        = var.ecs_execution_role_name
  ecs_execution_role_arn         = data.aws_iam_role.ecs_execution_role.arn
  ecs_task_role_name             = var.ecs_task_role_name
  ecs_task_role_arn              = data.aws_iam_role.ecs_task_role.arn

  ec2_template_instance_type = var.ec2_template_instance_type
  ec2_instance_profile_name  = var.ec2_instance_profile_name

  service_linked_role_arn = var.service_linked_role_arn

  load_balancer_external_security_group_id = var.load_balancer_external_security_group_id
  load_balancer_ingress_cidr_blocks        = var.load_balancer_ingress_cidr_blocks
  load_balancer_ingress_sg_id              = var.load_balancer_ingress_sg_id
  load_balancer_is_internal                = var.load_balancer_is_internal
  load_balancer_subnet_ids                 = var.load_balancer_subnet_ids
  load_balancer_idle_timeout               = var.load_balancer_idle_timeout
  load_balancer_listen_https               = var.load_balancer_listen_https
  load_balancer_ssl_cert_arn               = var.load_balancer_ssl_cert_arn

  database_password_secret_is_parameter_store = var.database_password_secret_is_parameter_store
  database_password_secret_name               = var.database_password_secret_name
  database_use_external                       = var.database_use_external
  database_port                               = var.database_port
  database_subnet_ids                         = var.database_subnet_ids
  rds_allocated_storage                       = var.rds_allocated_storage
  rds_max_allocated_storage                   = var.rds_max_allocated_storage
  database_engine                             = var.database_engine
  database_engine_version                     = var.database_engine_version
  rds_instance_type                           = var.rds_instance_type
  database_skip_final_snapshot                = var.database_skip_final_snapshot
}

resource "aws_lb_listener_rule" "mlflow_http_host_header" {
  count        = var.load_balancer_host_header != null ? 1 : 0
  listener_arn = var.launch_in_existing_cluster ? var.existing_lb_listener_arn : module.ecs_cluster.0.aws_lb_listener_arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = var.launch_in_existing_cluster ? var.existing_lb_target_group_arn : module.ecs_cluster.0.aws_lb_target_group_arn
  }
  condition {
    host_header {
      values = [var.load_balancer_host_header]
    }
  }
}

resource "aws_lb_listener_rule" "mlflow_https_host_header" {
  count        = var.load_balancer_host_header != null ? 1 : 0
  listener_arn = var.launch_in_existing_cluster ? var.existing_lb_listener_arn : module.ecs_cluster.0.aws_lb_listener_arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = var.launch_in_existing_cluster ? var.existing_lb_target_group_arn : module.ecs_cluster.0.aws_lb_target_group_arn
  }
  condition {
    host_header {
      values = [var.load_balancer_host_header]
    }
  }
}
