data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_secretsmanager_secret" "db_password" {
  arn = var.database_password_secret_arn
}

data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = data.aws_secretsmanager_secret.db_password.id
}

resource "aws_iam_role_policy" "db_secrets" {
  count = var.database_use_external ? 0 : 1
  name  = "${var.unique_name}-read-db-pass-secret"
  role  = local.ecs_execution_role_arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetResourcePolicy",
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds",
        ]
        Resource = [
          data.aws_secretsmanager_secret_version.db_password.arn,
        ]
      },
    ]
  })
}

resource "aws_db_subnet_group" "rds" {
  count      = var.database_use_external ? 0 : 1
  name       = "${var.unique_name}-rds"
  subnet_ids = var.database_subnet_ids
}

resource "aws_security_group" "rds" {
  count  = var.database_use_external ? 0 : 1
  name   = "${var.unique_name}-rds"
  vpc_id = var.vpc_id
  tags   = local.tags

  ingress {
    from_port       = local.db_port
    to_port         = local.db_port
    protocol        = "tcp"
    security_groups = [local.ecs_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_rds_cluster" "backend_store" {
  count                     = var.database_use_external ? 0 : 1
  cluster_identifier_prefix = var.unique_name
  tags                      = local.tags
  engine                    = var.database_engine
  engine_version            = var.database_engine_version
  engine_mode               = var.database_engine_mode
  port                      = local.db_port
  db_subnet_group_name      = aws_db_subnet_group.rds.0.name
  vpc_security_group_ids    = [aws_security_group.rds.0.id]
  availability_zones        = data.aws_availability_zones.available.names
  master_username           = "ecs_task"
  database_name             = "mlflow"
  skip_final_snapshot       = var.database_skip_final_snapshot
  final_snapshot_identifier = var.unique_name
  master_password           = data.aws_secretsmanager_secret_version.db_password.secret_string
  backup_retention_period   = 14

  scaling_configuration {
    max_capacity             = var.database_max_capacity
    min_capacity             = var.database_min_capacity
    auto_pause               = var.database_auto_pause
    seconds_until_auto_pause = var.database_seconds_until_auto_pause
    timeout_action           = "ForceApplyCapacityChange"
  }
}
