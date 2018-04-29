variable "kafka_ami_id" {
  description = "kafka ami id"
  default     = ""
}

variable "kafka_instance_type" {
  description = "kafka instance type"
  default     = "t2.small"
}


variable "user" {
  description = "user email"
}

variable "product" {
  description = "product name"
  default     = ""
}

variable "env" {
  description = "environment"
  default     = ""
}

variable "type" {
  description = "product type"
  default     = ""
}

variable "version" {
  description = "product version"
  default     = ""
}

variable "region" {
  description = "aws region"
  default     = "us-west-1"
}

variable "deployer_key_name" {
  description = "deployer key name"
  default     = ""
}

variable "instance_role_profile" {
  description = "instance role profile"
  default     = ""
}

variable "instance_role_name" {
  description = "instance role name"
  default     = ""
}

variable "server_number" {
  description = "kafka server number"
  default = ""
}

variable "vpc_id" {
  description = "VPC id"
}

variable "private_subnets" {
  description = "private subnet used for vpc zone identifier"
  type = "list"
}

variable "private_zone_id" {
  description = "private zone id"
}

variable "status_endpoint" {
  description = "health check point"
  default = "/status"
}

variable "jump_sg_id" {
  description = "jump server security group"
}

variable "app_server_sg" {
  description = "App server security group"
}


