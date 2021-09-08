resource "random_password" "mlflow_password" {
  count            = var.mlflow_generate_random_pass ? 1 : 0
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "aws_ssm_parameter" "mlflow_password" {
  count = var.mlflow_generate_random_pass ? 1 : 0
  name  = "${var.unique_name}-mlflow-password"
  type  = "SecureString"
  value = random_password.mlflow_password.0.result
  tags  = local.tags
}


resource "aws_iam_role_policy" "mlflow_parameters" {
  count = var.mlflow_generate_random_pass ? 1 : 0
  name  = "${var.unique_name}-read-mlflow-pass-secret"
  role  = local.ecs_execution_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameters"
        ]
        Resource = [
          aws_ssm_parameter.mlflow_password.0.arn
        ]
      },
    ]
  })
}

resource "aws_cloudwatch_log_group" "mlflow" {
  count             = var.cloudwatch_log_group_external_name != null ? 0 : 1
  name              = "/aws/ecs/${var.unique_name}"
  retention_in_days = var.service_log_retention_in_days
  tags              = local.tags
}

resource "aws_ecs_task_definition" "mlflow" {
  family = var.unique_name
  tags   = local.tags
  container_definitions = jsonencode(concat([
    {
      name  = "mlflow"
      image = var.service_image == null ? "larribas/mlflow:${var.service_image_tag}" : var.service_image
      repositoryCredentials = var.private_repository_secret != null ? {
        "credentialsParameter" : var.private_repository_secret
      } : null

      essential = true

      # As of version 1.9.1, MLflow doesn't support specifying the backend store uri as an environment variable. ECS doesn't allow evaluating secret environment variables from within the command. Therefore, we are forced to override the entrypoint and assume the docker image has a shell we can use to interpolate the secret at runtime.
      entryPoint = ["sh", "-c"]
      command = [
        "/bin/sh -c \"mlflow server --host=0.0.0.0 --port=${local.mlflow_port} --default-artifact-root=s3://${local.artifact_bucket_id}${var.artifact_bucket_path} --backend-store-uri=${var.backend_store_uri_engine}://${local.mlflow_backend_store_username}:`echo -n $DB_PASSWORD`@${local.mlflow_backend_store_endpoint}:${local.mlflow_backend_store_port}/${local.mlflow_backend_store_name} --gunicorn-opts '${var.gunicorn_opts}' \""
      ]
      portMappings = [{ containerPort = local.mlflow_port }]
      environment = concat([
        {
          name  = "MLFLOW_TRACKING_USERNAME"
          value = "mlflow"
        }
        ], !var.mlflow_generate_random_pass ? [
        {
          name  = "MLFLOW_TRACKING_PASSWORD"
          value = var.mlflow_pass
        }
      ] : [], jsondecode(var.mlflow_env_vars))
      secrets = concat([
        {
          name      = "DB_PASSWORD"
          valueFrom = local.db_password_arn
        }],
        var.mlflow_generate_random_pass ? [{
          name      = "MLFLOW_TRACKING_PASSWORD"
          valueFrom = aws_ssm_parameter.mlflow_password.0.arn
      }] : [])
      logConfiguration = {
        logDriver     = "awslogs"
        secretOptions = null
        options = {
          "awslogs-group"         = local.cloudwatch_log_group_external_name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "cis"
        }
      }
    },
    ], var.service_use_nginx_basic_auth ? [{
      name  = "nginx"
      image = var.service_nginx_basic_auth_image

      essential = true

      portMappings = [{ containerPort = local.service_port }]
      environment = concat([
        {
          name  = "MLFLOW_TRACKING_USERNAME"
          value = "mlflow"
        }
        ], !var.mlflow_generate_random_pass ? [
        {
          name  = "MLFLOW_TRACKING_PASSWORD"
          value = var.mlflow_pass
        }
      ] : [], jsondecode(var.mlflow_env_vars))
      secrets = var.mlflow_generate_random_pass ? [{
        name      = "MLFLOW_TRACKING_PASSWORD"
        valueFrom = aws_ssm_parameter.mlflow_password.0.arn
      }] : []
      logConfiguration = {
        logDriver     = "awslogs"
        secretOptions = null
        options = {
          "awslogs-group"         = local.cloudwatch_log_group_external_name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "cis"
        }
      }
  }] : [], var.service_sidecar_container_definitions))

  network_mode             = "awsvpc"
  task_role_arn            = local.ecs_task_role_arn
  execution_role_arn       = local.ecs_execution_role_arn
  requires_compatibilities = [var.ecs_launch_type]
  cpu                      = var.service_cpu
  memory                   = var.service_memory
}

resource "aws_ecs_service" "mlflow" {
  name                              = var.unique_name
  cluster                           = var.launch_in_existing_cluster ? var.existing_cluster_id : module.ecs_cluster.0.ecs_cluster_id
  task_definition                   = aws_ecs_task_definition.mlflow.arn
  desired_count                     = var.ecs_service_count
  launch_type                       = var.ecs_launch_type == "EC2" ? null : var.ecs_launch_type
  platform_version                  = var.ecs_launch_type == "EC2" ? null : "1.4.0"
  health_check_grace_period_seconds = 30

  capacity_provider_strategy {
    base              = 0
    capacity_provider = var.launch_in_existing_cluster ? var.existing_capacity_provider_name : module.ecs_cluster.0.capacity_provider_name
    weight            = 1
  }

  deployment_circuit_breaker {
    enable   = false
    rollback = false
  }

  deployment_controller {
    type = "ECS"
  }

  network_configuration {
    subnets         = var.service_subnet_ids
    security_groups = [local.ecs_security_group_id]
  }

  load_balancer {
    target_group_arn = var.launch_in_existing_cluster ? var.existing_lb_target_group_arn : module.ecs_cluster.0.aws_lb_target_group_arn
    container_name   = var.service_use_nginx_basic_auth ? "nginx" : "mlflow"
    container_port   = local.service_port
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  depends_on = [
    module.ecs_cluster
  ]
}

resource "aws_appautoscaling_target" "mlflow" {
  count              = var.ecs_launch_type == "EC2" ? 1 : 0
  service_namespace  = "ecs"
  resource_id        = "service/${var.launch_in_existing_cluster ? var.existing_cluster_id : module.ecs_cluster.0.ecs_cluster_id}/${aws_ecs_service.mlflow.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  max_capacity       = var.service_max_capacity
  min_capacity       = var.service_min_capacity
}
