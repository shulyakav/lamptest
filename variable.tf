variable "database_user" {
  description = "The user for the MySQL database"
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
# variable "database_host" {
#     description = "the internal DNS name for DB hosts"
#     type = string
  
# }

variable "asg_min_size" {
  description = "The minimum size of the Auto Scaling Group"
  type        = number
}

variable "asg_max_size" {
  description = "The maximum size of the Auto Scaling Group"
  type        = number
}

variable "asg_desired_capacity" {
  description = "The desired number of instances in the Auto Scaling Group"
  type        = number
}

variable "availability_zones" {
  description = "A list of availability zones in which to distribute the EC2 instances"
  type        = list(string)
}



variable "db_instance_type" {
   description = "The type of instance to star DB"
  type        = string
}

variable "web_instance_type" {
   description = "The type of instance to star DB"
  type        = string
}

variable "user_data" {
  description = "The user data script to initialize EC2 instances"
  type        = string
  default     = ""
}
