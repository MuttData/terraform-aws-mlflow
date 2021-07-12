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

data "aws_iam_role" "ecs_task" {
  count = var.create_iam_roles ? 0 : 1
  name  = var.ecs_task_role_name
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

data "aws_iam_role" "ecs_execution" {
  count = var.create_iam_roles ? 0 : 1
  name  = var.ecs_execution_role_name
}

resource "aws_iam_service_linked_role" "ecs" {
  count            = var.create_iam_roles ? 1 : 0
  aws_service_name = "ecs.amazonaws.com"
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  count      = var.create_iam_roles ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.ecs_execution.0.name
}
