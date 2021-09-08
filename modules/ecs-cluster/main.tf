data "aws_region" "current" {}

resource "aws_security_group" "ecs_service" {
  count = var.ecs_external_security_group_id != null ? 0 : 1
  name  = "${var.unique_name}-ecs-service"
  tags  = var.tags

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

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

resource "aws_ecs_cluster" "mlflow" {
  name               = var.unique_name
  capacity_providers = [var.ecs_launch_type == "EC2" ? aws_ecs_capacity_provider.mlflow.0.name : "FARGATE"]
  tags               = var.tags

  default_capacity_provider_strategy {
    capacity_provider = var.ecs_launch_type == "EC2" ? aws_ecs_capacity_provider.mlflow.0.name : "FARGATE"
  }

  # We need to terminate all instances before the cluster can be destroyed.
  # (Terraform would handle this automatically if the autoscaling group depended
  #  on the cluster, but we need to have the dependency in the reverse
  #  direction due to the capacity_providers field above).
  provisioner "local-exec" {
    when = destroy

    command = <<CMD
      # Get the list of capacity providers associated with this cluster
      CAP_PROVS="$(aws ecs describe-clusters --clusters "${self.arn}" \
        --query 'clusters[*].capacityProviders[*]' --output text)"

      # Now get the list of autoscaling groups from those capacity providers
      ASG_ARNS="$(aws ecs describe-capacity-providers \
        --capacity-providers "$CAP_PROVS" \
        --query 'capacityProviders[*].autoScalingGroupProvider.autoScalingGroupArn' \
        --output text)"

      if [ -n "$ASG_ARNS" ] && [ "$ASG_ARNS" != "None" ]
      then
        for ASG_ARN in $ASG_ARNS
        do
          ASG_NAME=$(echo $ASG_ARN | cut -d/ -f2-)

          # Set the autoscaling group size to zero
          aws autoscaling update-auto-scaling-group \
            --auto-scaling-group-name "$ASG_NAME" \
            --min-size 0 --max-size 0 --desired-capacity 0
        done
      fi
CMD
  }
}

data "aws_ami" "ecs_optimized_ami_linux" {
  count       = var.ecs_launch_type == "EC2" ? 1 : 0
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-2018.03.20210519-amazon-ecs-optimized"]
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
  count         = var.ecs_launch_type == "EC2" ? 1 : 0
  name          = "${var.unique_name}-launch-template"
  image_id      = data.aws_ami.ecs_optimized_ami_linux.0.id
  instance_type = var.ec2_template_instance_type
  user_data     = base64encode(data.template_file.mlflow_launch_template_user_data.rendered)
  tags          = var.tags

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [local.ecs_security_group_id]
    subnet_id                   = var.ecs_subnet_ids.0
  }

  iam_instance_profile {
    name = var.ec2_instance_profile_name
  }

  tag_specifications {
    resource_type = "instance"
    tags          = var.tags
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
  vpc_zone_identifier = var.ecs_subnet_ids

  lifecycle {
    ignore_changes = [force_delete_warm_pool]
  }

  tags = concat(
    [
      {
        key                 = "AmazonECSManaged"
        value               = ""
        propagate_at_launch = true
      },
      {
        key                 = "Name"
        value               = var.unique_name
        propagate_at_launch = true
      }
    ],
    [
      for tag_key, tag_value in var.tags :
      {
        key                 = tag_key
        value               = tag_value
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
      target_capacity           = 100
      maximum_scaling_step_size = 100
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
    }
  }

  depends_on = [
    aws_iam_service_linked_role.ecs
  ]
}

resource "aws_security_group" "lb" {
  count  = var.load_balancer_external_security_group_id != null ? 0 : 1
  name   = "${var.unique_name}-lb"
  tags   = var.tags
  vpc_id = var.vpc_id
}

resource "aws_security_group_rule" "lb_ingress_http" {
  description              = "Only allow load balancer to reach the ECS service on the right port"
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  cidr_blocks              = var.load_balancer_ingress_cidr_blocks
  source_security_group_id = var.load_balancer_ingress_sg_id
  security_group_id        = local.load_balancer_security_group_id
}

resource "aws_security_group_rule" "lb_ingress_https" {
  description              = "Only allow load balancer to reach the ECS service on the right port"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  cidr_blocks              = var.load_balancer_ingress_cidr_blocks
  source_security_group_id = var.load_balancer_ingress_sg_id
  security_group_id        = local.load_balancer_security_group_id
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
  tags               = var.tags
  internal           = var.load_balancer_is_internal ? true : false
  load_balancer_type = "application"
  security_groups    = [local.load_balancer_security_group_id]
  subnets            = var.load_balancer_subnet_ids
  idle_timeout       = var.load_balancer_idle_timeout
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
  count             = var.ecs_launch_type != "EC2" ? 0 : 1
  load_balancer_arn = aws_lb.mlflow.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.mlflow.arn
  }
}

resource "aws_lb_listener" "mlflow_https" {
  count             = var.ecs_launch_type == "EC2" && var.load_balancer_listen_https ? 1 : 0
  load_balancer_arn = aws_lb.mlflow.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.load_balancer_ssl_cert_arn
  depends_on        = [aws_lb_target_group.mlflow]

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.mlflow.arn
  }
}
