data "aws_region" "current" {}

resource "aws_iam_role" "ecs_task" {
  count = var.create_iam_roles ? 1 : 0
  name  = "${var.unique_name}-ecs-task"
  tags  = local.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Effect = "Allow"
      },
    ]
  })
}

resource "aws_iam_role" "ecs_execution" {
  count = var.create_iam_roles ? 1 : 0
  name  = "${var.unique_name}-ecs-execution"
  tags  = local.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Effect = "Allow"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  count      = var.create_iam_roles ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.ecs_execution.0.name
}

resource "aws_security_group" "ecs_service" {
  name = "${var.unique_name}-ecs-service"
  tags = local.tags

  vpc_id = var.vpc_id

  ingress {
    from_port       = local.service_port
    to_port         = local.service_port
    protocol        = "tcp"
    security_groups = [aws_security_group.lb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_cloudwatch_log_group" "mlflow" {
  count             = var.cloudwatch_log_group_external_arn ? 0 : 1
  name              = "/aws/ecs/${var.unique_name}"
  retention_in_days = var.service_log_retention_in_days
  tags              = local.tags
}

resource "aws_ecs_cluster" "mlflow" {
  name               = var.unique_name
  capacity_providers = [var.ecs_launch_type == "EC2" ? aws_ecs_capacity_provider.mlflow.name : "FARGATE"]
  default_capacity_provider_strategy {
    capacity_provider = var.ecs_launch_type == "EC2" ? aws_ecs_capacity_provider.mlflow.name : "FARGATE"
  }
  tags = local.tags
}

resource "aws_ecs_task_definition" "mlflow" {
  family = var.unique_name
  tags   = local.tags
  container_definitions = jsonencode(concat([
    {
      name      = "mlflow"
      image     = "larribas/mlflow:${var.service_image_tag}"
      essential = true

      # As of version 1.9.1, MLflow doesn't support specifying the backend store uri as an environment variable. ECS doesn't allow evaluating secret environment variables from within the command. Therefore, we are forced to override the entrypoint and assume the docker image has a shell we can use to interpolate the secret at runtime.
      entryPoint = ["sh", "-c"]
      command = [
        "/bin/sh -c \"mlflow server --host=0.0.0.0 --port=${local.service_port} --default-artifact-root=s3://${local.artifact_bucket_id}${var.artifact_bucket_path} --backend-store-uri=${var.backend_store_uri_engine}://${var.database_use_external ? var.database_external_username : aws_rds_cluster.backend_store.master_username}:`echo -n $DB_PASSWORD`@${var.database_use_external ? var.database_external_host : aws_rds_cluster.backend_store.endpoint}:${var.database_use_external ? var.database_external_port : aws_rds_cluster.backend_store.port}/${var.database_use_external ? var.database_external_name : aws_rds_cluster.backend_store.database_name} --gunicorn-opts '${var.gunicorn_opts}' \""
      ]
      portMappings = [{ containerPort = local.service_port }]
      secrets = [
        {
          name      = "DB_PASSWORD"
          valueFrom = data.aws_secretsmanager_secret.db_password.arn
        },
      ]
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
  ], var.service_sidecar_container_definitions))

  network_mode             = "awsvpc"
  task_role_arn            = local.ecs_task_role_arn
  execution_role_arn       = local.ecs_execution_role_arn
  requires_compatibilities = [var.ecs_launch_type]
  cpu                      = var.service_cpu
  memory                   = var.service_memory
}

resource "aws_ecs_service" "mlflow" {
  name             = var.unique_name
  cluster          = aws_ecs_cluster.mlflow.id
  task_definition  = aws_ecs_task_definition.mlflow.arn
  desired_count    = var.ecs_service_count
  launch_type      = var.ecs_launch_type
  platform_version = "1.4.0"


  network_configuration {
    subnets         = var.service_subnet_ids
    security_groups = [aws_security_group.ecs_service.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.mlflow.arn
    container_name   = "mlflow"
    container_port   = local.service_port
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  depends_on = [
    aws_lb.mlflow,
  ]
}

data "aws_ami" "ecs_optimized_ami_linux" {
  count       = var.ecs_launch_type == "EC2" ? 1 : 0
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-*-amazon-ecs-optimized"]
  }
}

resource "aws_launch_template" "mlflow" {
  count                  = var.ecs_launch_type == "EC2" ? 1 : 0
  name                   = "${var.unique_name}-launch-template"
  image_id               = data.aws_ami.ecs_optimized_ami_linux.0.id
  iam_instance_profile   = "ecsInstanceRole"
  instance_type          = var.ec2_template_instance_type
  user_data              = <<EOF
#!/bin/bash
# The cluster this agent should check into.
echo 'ECS_CLUSTER=${var.unique_name}' >> /etc/ecs/ecs.config
# Disable privileged containers.
echo 'ECS_DISABLE_PRIVILEGED=true' >> /etc/ecs/ecs.config
EOF
  vpc_security_group_ids = [aws_security_group.ecs_service.id]
}

resource "aws_autoscaling_group" "mlflow" {
  count    = var.ecs_launch_type == "EC2" ? 1 : 0
  name     = "${var.unique_name}-asg"
  min_size = var.ecs_min_instance_count
  max_size = var.ecs_max_instance_count
  launch_template {
    id      = aws_launch_template.mlflow.0.id
    version = "$Latest"
  }
  vpc_zone_identifier = var.service_subnet_ids
  tag {
    key                 = "AmazonECSManaged"
    value               = ""
    propagate_at_launch = true
  }
}

resource "aws_ecs_capacity_provider" "mlflow" {
  count = var.ecs_launch_type == "EC2" ? 1 : 0
  name  = "${var.unique_name}-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.mlflow.0.arn
    managed_termination_protection = "ENABLED"

    managed_scaling {
      target_capacity           = 90
      maximum_scaling_step_size = 100
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
    }
  }
}

resource "aws_appautoscaling_target" "mlflow" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.mlflow.name}/${aws_ecs_service.mlflow.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  max_capacity       = var.service_max_capacity
  min_capacity       = var.service_min_capacity
}

resource "aws_security_group" "lb" {
  name   = "${var.unique_name}-lb"
  tags   = local.tags
  vpc_id = var.vpc_id
}

resource "aws_security_group_rule" "lb_ingress_http" {
  description       = "Only allow load balancer to reach the ECS service on the right port"
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = var.load_balancer_ingress_cidr_blocks
  security_group_id = aws_security_group.lb.id
}

resource "aws_security_group_rule" "lb_ingress_https" {
  description       = "Only allow load balancer to reach the ECS service on the right port"
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.load_balancer_ingress_cidr_blocks
  security_group_id = aws_security_group.lb.id
}

resource "aws_security_group_rule" "lb_egress" {
  description              = "Only allow load balancer to reach the ECS service on the right port"
  type                     = "egress"
  from_port                = local.service_port
  to_port                  = local.service_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs_service.id
  security_group_id        = aws_security_group.lb.id
}

resource "aws_lb" "mlflow" {
  name               = var.unique_name
  tags               = local.tags
  internal           = var.load_balancer_is_internal ? true : false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb.id]
  subnets            = var.load_balancer_subnet_ids
}

resource "aws_lb_target_group" "mlflow" {
  name        = var.unique_name
  port        = local.service_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    protocol = "HTTP"
    matcher  = "200-202"
    path     = "/health"
  }
}

