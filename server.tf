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
  count = var.ecs_external_security_group_id != null ? 0 : 1
  name  = "${var.unique_name}-ecs-service"
  tags  = local.tags

  vpc_id = var.vpc_id
}

resource "aws_security_group_rule" "ecs_service_ingress_http" {
  description              = "Only allow load balancer to reach the ECS service on the right port"
  type                     = "ingress"
  from_port                = local.service_port
  to_port                  = local.service_port
  protocol                 = "tcp"
  source_security_group_id = local.load_balancer_security_group_id
  security_group_id        = local.ecs_security_group_id
}

resource "aws_cloudwatch_log_group" "mlflow" {
  count             = var.cloudwatch_log_group_external_name != null ? 0 : 1
  name              = "/aws/ecs/${var.unique_name}"
  retention_in_days = var.service_log_retention_in_days
  tags              = local.tags
}

resource "aws_ecs_cluster" "mlflow" {
  name               = var.unique_name
  capacity_providers = [var.ecs_launch_type == "EC2" ? aws_ecs_capacity_provider.mlflow.0.name : "FARGATE"]
  default_capacity_provider_strategy {
    capacity_provider = var.ecs_launch_type == "EC2" ? aws_ecs_capacity_provider.mlflow.0.name : "FARGATE"
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
        "/bin/sh -c \"mlflow server --host=0.0.0.0 --port=${local.service_port} --default-artifact-root=s3://${local.artifact_bucket_id}${var.artifact_bucket_path} --backend-store-uri=${var.backend_store_uri_engine}://${local.mlflow_backend_store_username}:`echo -n $DB_PASSWORD`@${local.mlflow_backend_store_endpoint}:${local.mlflow_backend_store_port}/${local.mlflow_backend_store_port_name} --gunicorn-opts '${var.gunicorn_opts}' \""
      ]
      portMappings = [{ containerPort = local.service_port }]
      environment  = jsondecode(var.mlflow_env_vars)
      secrets = [
        {
          name      = "DB_PASSWORD"
          valueFrom = local.db_password_arn
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
  platform_version = var.ecs_launch_type == "EC2" ? null : "1.4.0" 


  network_configuration {
    subnets         = var.service_subnet_ids
    security_groups = [local.ecs_security_group_id]
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

data "template_file" "mlflow_launch_template_user_data" {
  template = <<EOF
#!/bin/bash
# The cluster this agent should check into.
echo ECS_CLUSTER=${var.unique_name} >> /etc/ecs/ecs.config
# Disable privileged containers.
echo ECS_DISABLE_PRIVILEGED=true >> /etc/ecs/ecs.config
EOF
}

resource "aws_launch_template" "mlflow" {
  count                  = var.ecs_launch_type == "EC2" ? 1 : 0
  name                   = "${var.unique_name}-launch-template"
  image_id               = data.aws_ami.ecs_optimized_ami_linux.0.id
  instance_type          = var.ec2_template_instance_type
  vpc_security_group_ids = [local.ecs_security_group_id]
  user_data              = base64encode(data.template_file.mlflow_launch_template_user_data.rendered)
  tags                   = local.tags

  network_interfaces {
    associate_public_ip_address = true
  }
  
  iam_instance_profile {
    name = var.ec2_instance_profile_name
  }

  tag_specifications {
    resource_type = "instance"
    tags          = local.tags
  }
}

resource "aws_autoscaling_group" "mlflow" {
  count                   = var.ecs_launch_type == "EC2" ? 1 : 0
  name                    = "${var.unique_name}-asg"
  min_size                = var.ecs_min_instance_count
  max_size                = var.ecs_max_instance_count
  service_linked_role_arn = var.service_linked_role_arn
  launch_template {
    id      = aws_launch_template.mlflow.0.id
    version = aws_launch_template.mlflow.0.latest_version
  }
  vpc_zone_identifier = var.service_subnet_ids
  
  tags = concat(
    [
      {
        key                 = "AmazonECSManaged"
        value               = ""
        propagate_at_launch = true
      }
    ],
    [
      for tag_key, tag_value in local.tags:
      {
        key = tag_key
        value = tag_value
        propagate_at_launch = true
      }
    ],
  )
}

resource "aws_ecs_capacity_provider" "mlflow" {
  count = var.ecs_launch_type == "EC2" ? 1 : 0
  name  = "${var.unique_name}-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.mlflow.0.arn
    managed_termination_protection = "DISABLED"

    managed_scaling {
      target_capacity           = 90
      maximum_scaling_step_size = 100
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
    }
  }
}

resource "aws_appautoscaling_target" "mlflow" {
  count = var.ecs_launch_type == "EC2" ? 1 : 0
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.mlflow.name}/${aws_ecs_service.mlflow.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  max_capacity       = var.service_max_capacity
  min_capacity       = var.service_min_capacity
}

resource "aws_security_group" "lb" {
  count  = var.load_balancer_external_security_group_id != null ? 0 : 1
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
  security_group_id = local.load_balancer_security_group_id
}

resource "aws_security_group_rule" "lb_ingress_https" {
  description       = "Only allow load balancer to reach the ECS service on the right port"
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.load_balancer_ingress_cidr_blocks
  security_group_id = local.load_balancer_security_group_id
}

resource "aws_security_group_rule" "lb_egress" {
  description              = "Only allow load balancer to reach the ECS service on the right port"
  type                     = "egress"
  from_port                = local.service_port
  to_port                  = local.service_port
  protocol                 = "tcp"
  source_security_group_id = local.ecs_security_group_id
  security_group_id        = local.load_balancer_security_group_id
}

resource "aws_lb" "mlflow" {
  name               = var.unique_name
  tags               = local.tags
  internal           = var.load_balancer_is_internal ? true : false
  load_balancer_type = "application"
  security_groups    = [local.load_balancer_security_group_id]
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

resource "aws_lb_listener" "mlflow" {
  count  = var.ecs_launch_type != "EC2" ? 0 : 1
  load_balancer_arn = aws_lb.mlflow.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.mlflow.arn
  }
}
