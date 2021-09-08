data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_secretsmanager_secret" "db_password" {
  count = var.database_password_secret_is_parameter_store ? 0 : 1
  name  = var.database_password_secret_name
}

data "aws_secretsmanager_secret_version" "db_password" {
  count     = var.database_password_secret_is_parameter_store ? 0 : 1
  secret_id = data.aws_secretsmanager_secret.db_password.0.id
}

data "aws_ssm_parameter" "db_password" {
  count = var.database_password_secret_is_parameter_store ? 1 : 0
  name  = var.database_password_secret_name
}

resource "aws_iam_role_policy" "db_secrets" {
  count = var.database_use_external || var.database_password_secret_is_parameter_store ? 0 : 1
  name  = "${var.unique_name}-read-db-pass-secret"
  role  = local.ecs_execution_role_name

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
          data.aws_secretsmanager_secret_version.db_password.0.arn,
        ]
      },
    ]
  })
}

resource "aws_iam_role_policy" "db_parameters" {
  count = var.database_use_external || var.database_password_secret_is_parameter_store == false ? 0 : 1
  name  = "${var.unique_name}-read-db-pass-secret"
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
          data.aws_ssm_parameter.db_password.0.arn
        ]
      },
    ]
  })
}

resource "aws_db_subnet_group" "rds" {
  count      = var.database_use_external ? 0 : 1
  name       = "${var.unique_name}-rds"
  subnet_ids = var.database_subnet_ids
  tags       = var.tags
}

resource "aws_security_group" "rds" {
  count  = var.database_use_external ? 0 : 1
  name   = "${var.unique_name}-rds"
  vpc_id = var.vpc_id
  tags   = var.tags

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

resource "aws_db_instance" "backend_store" {
  count                   = var.database_use_external ? 0 : 1
  identifier              = "${var.unique_name}-metadata-rds"
  allocated_storage       = var.rds_allocated_storage
  max_allocated_storage   = var.rds_max_allocated_storage
  tags                    = var.tags
  name                    = "mlflow"
  engine                  = var.database_engine
  engine_version          = var.database_engine_version
  username                = "mlflow"
  password                = local.db_password_value
  instance_class          = var.rds_instance_type
  port                    = 5432
  db_subnet_group_name    = aws_db_subnet_group.rds.0.name
  vpc_security_group_ids  = [aws_security_group.rds.0.id]
  availability_zone       = data.aws_availability_zones.available.names.0
  backup_retention_period = 14
  skip_final_snapshot     = var.database_skip_final_snapshot
}
