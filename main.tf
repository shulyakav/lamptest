module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.7.0"

  name = "lamp-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-west-2a", "us-west-2b", "us-west-2c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
 
  manage_default_route_table = true
  enable_nat_gateway = true
  enable_vpn_gateway = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}


module "asg_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.1.2"

  name        = "web-server"
  description = "A security group apply to ALB"
  vpc_id      = module.vpc.vpc_id

  computed_ingress_with_source_security_group_id = [
    {
      rule                     = "http-80-tcp"
      source_security_group_id = module.alb.security_group_id
    }
  ]
  number_of_computed_ingress_with_source_security_group_id = 1

  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules = ["all-all"]

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

module "web_server_sg" {
  source = "terraform-aws-modules/security-group/aws"
  version = "~> 5.1.2"
  name        = "web-server"
  description = "Security group for web-server with HTTP ports open for all, and 443 for VPC (for SSM)"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks      = ["10.0.0.0/16"]
  ingress_rules            = ["https-443-tcp", "ssh-tcp"]
  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "User-service ports"
      cidr_blocks = "0.0.0.0/0"
    },
    # {
    #   rule        = "rule-name"
    #   cidr_blocks = "0.0.0.0/0"
    # },
  ]
  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules = ["all-all"]

}


module "db_server_sg" {
  source = "terraform-aws-modules/security-group/aws"
  version = "~> 5.1.2"
  name        = "db-server"
  description = "Security group for web-server to allow comunications with DB only from ASG instances + SSM connect in VPC"
  vpc_id      = module.vpc.vpc_id
  ingress_cidr_blocks      = ["10.0.0.0/16"]
  ingress_rules            = ["https-443-tcp", "ssh-tcp"]
  

  ingress_with_source_security_group_id = [
    {
      rule                     = "mysql-tcp"
      source_security_group_id = module.web_server_sg.security_group_id
    },
  ]
  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules = ["all-all"]
  

}


module "secret_manager" {
  source = "./modules/secret_manager"
}

module "database_server" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.6.1"

  name = "database-server"

  ignore_ami_changes = true

  ami               = data.aws_ami.amazon-linux-2.id
  key_name          = "test"
  instance_type     = var.db_instance_type
  availability_zone = element(module.vpc.azs, 0)
  subnet_id              = element(module.vpc.private_subnets, 0) 
  #Ssubnet_id              = element(module.vpc.public_subnets, 0) # fro test only
  create_iam_instance_profile = true
  iam_role_name               = "DB-TestSSM"
  iam_role_path               = "/ec2/"
  iam_role_description        = "Complete IAM role example"
  iam_role_tags = {
    CustomIamRole = "Yes"
  }

  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
  }
  vpc_security_group_ids = [module.db_server_sg.security_group_id]
  user_data = templatefile("./db/setup_mysql.sh", {
    database_user     = var.database_user,
    database_password = data.aws_secretsmanager_secret_version.password.secret_string,
    database_name     = var.database_name,
    table_name        = var.table_name
  })
  depends_on = [module.vpc]
}


module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.8.0"
  name    = "lamp-alb"
  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.public_subnets

  # For example only
  enable_deletion_protection = false

  # Security Group
  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = module.vpc.vpc_cidr_block
    }
  }

  listeners = {
    ex_http = {
      port     = 80
      protocol = "HTTP"

      forward = {
        target_group_key = "ex_asg"
      }
    }
  }

  target_groups = {
    ex_asg = {
      backend_protocol                  = "HTTP"
      backend_port                      = 80
      target_type                       = "instance"
      deregistration_delay              = 5
      load_balancing_cross_zone_enabled = true
      create_attachment = false
    }
  }

    tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}


module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 7.4.1"

  name = "lamp-asg"

  min_size                  = 0
  max_size                  = 1
  desired_capacity          = 1
  wait_for_capacity_timeout = 0
  default_instance_warmup   = 300
  health_check_type         = "EC2"
  vpc_zone_identifier  = module.vpc.private_subnets
  launch_template_name = "lamp_aws_launch_template"
  user_data = base64encode(templatefile("web_app/setup.sh", {
    database_host     = module.database_server.private_dns,
    database_user     = var.database_user,
    database_password = data.aws_secretsmanager_secret_version.password.secret_string,
    database_name     = var.database_name,
    table_name        = var.table_name,
  }))


  image_id      = data.aws_ami.amazon-linux-2.id
  instance_type = var.web_instance_type


  create_iam_instance_profile = true
  iam_role_name               = "complete-TestSSM"
  iam_role_path               = "/ec2/"
  iam_role_description        = "Complete IAM role example"
  iam_role_tags = {
    CustomIamRole = "Yes"
  }

  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
  }
  # Traffic source attachment
  create_traffic_source_attachment = true
  traffic_source_identifier        = module.alb.target_groups["ex_asg"].arn
  traffic_source_type              = "elbv2"
  security_groups                  = [module.web_server_sg.security_group_id]

  # Scale Policy
   scaling_policies = {
    avg-cpu-policy-greater-than-50 = {
      policy_type               = "TargetTrackingScaling"
      estimated_instance_warmup = 1200
      target_tracking_configuration = {
        predefined_metric_specification = {
          predefined_metric_type = "ASGAverageCPUUtilization"
        }
        target_value = 50.0
      }
    },
    predictive-scaling = {
      policy_type = "PredictiveScaling"
      predictive_scaling_configuration = {
        mode                         = "ForecastAndScale"
        scheduling_buffer_time       = 10
        max_capacity_breach_behavior = "IncreaseMaxCapacity"
        max_capacity_buffer          = 10
        metric_specification = {
          target_value = 32
          predefined_scaling_metric_specification = {
            predefined_metric_type = "ASGAverageCPUUtilization"
            resource_label         = "testLabel"
          }
          predefined_load_metric_specification = {
            predefined_metric_type = "ASGTotalCPUUtilization"
            resource_label         = "testLabel"
          }
        }
      }
    }
    request-count-per-target = {
      policy_type               = "TargetTrackingScaling"
      estimated_instance_warmup = 120
      target_tracking_configuration = {
        predefined_metric_specification = {
          predefined_metric_type = "ALBRequestCountPerTarget"
          resource_label         = "${module.alb.arn_suffix}/${module.alb.target_groups["ex_asg"].arn_suffix}"
        }
        target_value = 800
      }
    }
    scale-out = {
      name                      = "scale-out"
      adjustment_type           = "ExactCapacity"
      policy_type               = "StepScaling"
      estimated_instance_warmup = 120
      step_adjustment = [
        {
          scaling_adjustment          = 1
          metric_interval_lower_bound = 0
          metric_interval_upper_bound = 10
        },
        {
          scaling_adjustment          = 2
          metric_interval_lower_bound = 10
        }
      ]
    }
  }


  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
  depends_on = [module.alb]
}

#have no time to finish it.
# module "vpc_endpoints" {
#   source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
#   version = "~> 5.0"

#   vpc_id = module.vpc.vpc_id

#   endpoints = { for service in toset(["ssm", "ssmmessages", "ec2messages"]) :
#     replace(service, ".", "_") =>
#     {
#       service             = service
#       subnet_ids          = module.vpc.intra_subnets
#       private_dns_enabled = true
#       tags                = { Name = "LAMP" }
#     }
#   }

#   create_security_group      = true
#   security_group_name_prefix = "LAMP-vpc-endpoints-"
#   security_group_description = "VPC endpoint security group"
#   security_group_rules = {
#     ingress_https = {
#       description = "HTTPS from subnets"
#       cidr_blocks = module.vpc.intra_subnets_cidr_blocks
#     }
#   }

#   tags = local.tags
# }
