locals {
  account_id = data.aws_caller_identity.current.account_id
}

variable "ami" {}
variable "instance_type" {}
variable "db_instance_type" {  
}

variable "env" {
  default     = "dev"
  description = "The environment to deploy to"
}

variable "region" {
  default     = "us-west-2"
  description = "The region to deploy to"
}

variable "application" {
  default     = "my-app"
  description = "The application name tag"
}

variable "service" {
  default     = "my-service"
  description = "The service name tag"
}



variable "database_user" {
  description = "The user for the MySQL database"
  type        = string
}

variable "database_password" {
  description = "The password for the MySQL database user"
  type        = string
}

variable "database_name" {
  description = "The name of the MySQL database"
  type        = string
}

variable "table_name" {
  description = "The name of the table to query"
  type        = string
}

variable "subnet_id" {
  description = "The ID of the subnet to launch the instance in."
  type        = string
}
