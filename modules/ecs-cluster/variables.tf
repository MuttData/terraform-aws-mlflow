variable "unique_name" {
  default = null
}

variable "tags" {
  default = null
}
variable "vpc_id" {
  default = null
}

variable "create_iam_roles" {
  type        = bool
  default     = true
  description = "By default the module will create all necessary roles, if you want to use existing set this to false."
}

variable "ecs_launch_type" {
  default = null
}

variable "ecs_subnet_ids" {
  default = null
}

variable "ecs_min_instance_count" {
  default = null
}
variable "ecs_max_instance_count" {
  default = null
}

variable "ecs_external_security_group_id" {
  default = null
}

variable "ecs_execution_role_name" {
  default = null
}

variable "ecs_execution_role_arn" {
  default = null
}

variable "ecs_task_role_name" {
  default = null
}

variable "ecs_task_role_arn" {
  default = null
}

variable "ec2_template_instance_type" {
  default = null
}

variable "ec2_instance_profile_name" {
  default = null
}
variable "service_linked_role_arn" {
  default = null
}

variable "load_balancer_external_security_group_id" {
  default = null
}

variable "load_balancer_ingress_cidr_blocks" {
  default = null
}
variable "load_balancer_ingress_sg_id" {
  default = null
}

variable "load_balancer_is_internal" {
  default = null
}

variable "load_balancer_subnet_ids" {
  default = null
}
variable "load_balancer_idle_timeout" {
  default = null
}
variable "load_balancer_listen_https" {
  default = null
}
variable "load_balancer_ssl_cert_arn" {
  default = null
}

variable "database_password_secret_is_parameter_store" {
  default = null
}
variable "database_password_secret_name" {
  default = null
}
variable "database_use_external" {
  default = null
}
variable "database_subnet_ids" {
  default = null
}
variable "rds_allocated_storage" {
  default = null
}
variable "rds_max_allocated_storage" {
  default = null
}
variable "database_engine" {
  default = null
}
variable "database_engine_version" {
  default = null
}
variable "rds_instance_type" {
  default = null
}
variable "database_skip_final_snapshot" {
  default = null
}

variable "database_port" {
  default = null
}
