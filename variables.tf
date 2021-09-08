variable "unique_name" {
  type        = string
  description = "A unique name for this application (e.g. mlflow-team-name)"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "AWS Tags common to all the resources created"
}

variable "vpc_id" {
  type        = string
  description = "AWS VPC to deploy MLflow into"
}

variable "launch_in_existing_cluster" {
  type        = bool
  default     = false
  description = "If you want to launch a new mlflow instance in an existing ECS cluster"
}

variable "existing_cluster_id" {
  type        = string
  default     = null
  description = "Existing ECS cluster id"
}

variable "existing_lb_listener_arn" {
  type        = string
  default     = null
  description = "Existing ECS load balancer listener ARN"
}

variable "existing_lb_target_group_arn" {
  type        = string
  default     = null
  description = "Existing ECS load balancer target group ARN"
}

variable "existing_capacity_provider_name" {
  type        = string
  default     = null
  description = "Existing ECS capacity provider name"
}

variable "existing_service_execution_role_id" {
  type    = string
  default = null
}
variable "existing_service_task_role_id" {
  type    = string
  default = null
}

variable "create_iam_roles" {
  type        = bool
  default     = true
  description = "By default the module will create all necessary roles, if you want to use existing set this to false."
}

variable "ecs_task_role_name" {
  type        = string
  default     = null
  description = "ECS task role name."
}

variable "ecs_execution_role_name" {
  type        = string
  default     = null
  description = "ECS execution role name."
}

variable "ecs_launch_type" {
  type        = string
  default     = "FARGATE"
  description = "ECS launch type. Can be EC2 or FARGATE, by default FARGATE."
}

variable "ec2_template_instance_type" {
  type        = string
  default     = null
  description = "EC2 template instance type. Mandatory if ecs_launch_type is EC2"
}

variable "ec2_instance_profile_name" {
  type        = string
  default     = null
  description = " The IAM Instance Profile to launch the instance with."
}

variable "ecs_service_count" {
  type        = number
  default     = 2
  description = "Number of replicas to deploy. Defualt 2."
}

variable "ecs_min_instance_count" {
  type        = number
  default     = 1
  description = "Minimum number of instances for the ecs cluster."
}

variable "ecs_max_instance_count" {
  type        = number
  default     = 2
  description = "Maximum number of instances for the ecs cluster."
}

variable "ecs_external_security_group_id" {
  type        = string
  default     = null
  description = "If you want to use an existing security group for the ECS service instead of creting a new one."
}

variable "ecs_subnet_ids" {
  type        = list(string)
  description = "List of subnets where the ECS cluster instances will be deployed"
}

variable "cloudwatch_log_group_external_name" {
  type        = string
  default     = null
  description = "To use an existing cloud watch log group, name."
}

variable "load_balancer_subnet_ids" {
  type        = list(string)
  description = "List of subnets where the Load Balancer will be deployed"
}

variable "load_balancer_idle_timeout" {
  type        = number
  default     = 60
  description = "Load balancer idle timeout in seconds; default: 60 seconds"
}

variable "load_balancer_ingress_cidr_blocks" {
  type        = list(string)
  default     = null
  description = "CIDR blocks from where to allow traffic to the Load Balancer. If this is null, load_balancer_ingress_sg_id must be set."
}

variable "load_balancer_ingress_sg_id" {
  type        = string
  default     = null
  description = "Security group from where to allow traffic to the Load Balancer. If this is null, load_balancer_ingress_cidr_blocks must be set."
}

variable "load_balancer_is_internal" {
  type        = bool
  default     = true
  description = "By default, the load balancer is internal. This is because as of v1.9.1, MLflow doesn't have native authentication or authorization. We recommend exposing MLflow behind a VPN or using OIDC/Cognito together with the LB listener."
}

variable "load_balancer_external_security_group_id" {
  type        = string
  default     = null
  description = "If you want to use an existing security group for the lb instead of creting a new one."
}

variable "load_balancer_listen_https" {
  type        = bool
  default     = false
  description = "If you want the load balancer to support HTTPS."
}

variable "load_balancer_ssl_cert_arn" {
  type        = string
  default     = null
  description = "If you want the load balancer to support HTTPS, the SSL certificate to use."
}

variable "load_balancer_host_header" {
  type        = string
  default     = null
  description = "If you want to listen to a specific host header."
}

variable "service_image" {
  type        = string
  default     = null
  description = "The MLflow docker image to deploy, if not by default it will get https://hub.docker.com/r/larribas/mlflow from the public registry"
}

variable "service_subnet_ids" {
  type        = list(string)
  description = "List of subnets where the MLflow ECS service will be deployed (the recommendation is to use subnets that cannot be accessed directly from the Internet)"
}

variable "service_image_tag" {
  type        = string
  default     = "1.9.1"
  description = "The MLflow version to deploy. Note that this version has to be available as a tag here: https://hub.docker.com/r/larribas/mlflow"
}

variable "private_repository_secret" {
  type        = string
  default     = null
  description = "The ARN of the secret that has the credentials to your private image repository."
}

variable "service_cpu" {
  type        = number
  default     = 2048
  description = "The number of CPU units reserved for the MLflow container"
}

variable "service_memory" {
  type        = number
  default     = 3886
  description = "The amount (in MiB) of memory reserved for the MLflow container"
}

variable "service_log_retention_in_days" {
  type        = number
  default     = 90
  description = "The number of days to keep logs around"
}

variable "service_sidecar_container_definitions" {
  default     = []
  description = "A list of container definitions to deploy alongside the main container. See: https://www.terraform.io/docs/providers/aws/r/ecs_task_definition.html#container_definitions"
}

variable "service_min_capacity" {
  type        = number
  default     = 2
  description = "Minimum number of instances for the ecs service. This will create an aws_appautoscaling_target that can later on be used to autoscale the MLflow instance"
}

variable "service_max_capacity" {
  type        = number
  default     = 2
  description = "Maximum number of instances for the ecs service. This will create an aws_appautoscaling_target that can later on be used to autoscale the MLflow instance"
}

variable "service_linked_role_arn" {
  type        = string
  default     = null
  description = "The ARN of the service-linked role that the ASG will use to call other AWS services. If left empty will use the default AWSServiceRoleForAutoScaling."
}

variable "service_use_nginx_basic_auth" {
  type        = bool
  default     = false
  description = "If to use an nginx server ahead of Mlflow with basic auth."
}

variable "service_nginx_basic_auth_image" {
  type        = string
  default     = null
  description = "Image to use for the nginx server."
}

variable "mlflow_env_vars" {
  type        = string
  default     = "{}"
  description = "Mlflow environment variables to inject in the container"
}

variable "mlflow_generate_random_pass" {
  type        = bool
  default     = false
  description = "If you want a random password to be generated for mlflow, or you'll inject one."
}

variable "mlflow_pass" {
  type        = string
  default     = "mlflow"
  description = "Mlflow tracking password."
}

variable "database_use_external" {
  type        = bool
  default     = false
  description = "If to create a database cluster or use an existing database."
}

variable "database_external_username" {
  type        = string
  default     = null
  description = "ECS execution role ARN."
}

variable "database_external_host" {
  type        = string
  default     = null
  description = "Database host, if using external."
}

variable "database_external_port" {
  type        = string
  default     = null
  description = "Database port, if using external."
}

variable "database_external_name" {
  type        = string
  default     = null
  description = "Database name, if using external."
}

variable "database_engine" {
  type        = string
  default     = "postgres"
  description = "Database engine, default 'postgres'."
}

variable "database_engine_version" {
  type        = string
  default     = "12.5"
  description = "Database version, default '12.5'."
}

variable "database_port" {
  type        = string
  default     = 5432
  description = "Database port, default 5432 (Potgres)."
}

variable "database_subnet_ids" {
  type        = list(string)
  default     = null
  description = "List of subnets where the RDS database will be deployed"
}

variable "database_password_secret_name" {
  type        = string
  description = "The name of the SecretManager/ParameterStore secret that defines the database password. It needs to be created before calling the module"
}

variable "database_password_secret_is_parameter_store" {
  type        = bool
  default     = false
  description = "Specifies if your database password secret is stored in the parameter store, by default false and we assume it is in the secrets manager"
}

variable "database_skip_final_snapshot" {
  type    = bool
  default = false
}
variable "rds_instance_type" {
  type        = string
  default     = "db.t3.medium"
  description = "RDS instance type for metadata."
}
variable "rds_allocated_storage" {
  type        = number
  default     = 10
  description = "RDS intial allocated storage."
}
variable "rds_max_allocated_storage" {
  type        = number
  default     = 50
  description = "RDS max allocated storage for storage autoscaling."
}

variable "backend_store_uri_engine" {
  type        = string
  default     = "postgresql+psycopg2"
  description = "Mlflow backend store uri engine to use. Default: postgresql+psycopg2."
}

variable "artifact_bucket_id" {
  type        = string
  default     = null
  description = "If specified, MLflow will use this bucket to store artifacts. Otherwise, this module will create a dedicated bucket. When overriding this value, you need to enable the task role to access the root you specified"
}

variable "artifact_bucket_path" {
  type        = string
  default     = "/"
  description = "The path within the bucket where MLflow will store its artifacts"
}

variable "artifact_buckets_mlflow_will_read" {
  description = "A list of bucket IDs MLflow will need read access to, in order to show the stored artifacts. It accepts any valid IAM resource, including ARNs with wildcards, so you can do something like arn:aws:s3:::bucket-prefix-*"
  type        = list(string)
  default     = []
}

variable "artifact_bucket_encryption_algorithm" {
  description = "Algorithm used for encrypting the default bucket."
  type        = string
  default     = "AES256"
}

variable "artifact_bucket_encryption_key_arn" {
  description = "ARN of the key used to encrypt the bucket. Only needed if you set aws:kms as encryption algorithm."
  type        = string
  default     = null
}

variable "gunicorn_opts" {
  description = "Additional command line options forwarded to gunicorn processes (https://mlflow.org/docs/latest/cli.html#cmdoption-mlflow-server-gunicorn-opts)"
  type        = string
  default     = ""
}
