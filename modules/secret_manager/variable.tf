locals {
  account_id = data.aws_caller_identity.current.account_id
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
