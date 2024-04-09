resource "aws_instance" "db" {
  ami                    = data.aws_ami.amazon-linux-2.id
  instance_type          = var.db_instance_type
  subnet_id              = var.subnet_id 
  security_groups        = aws_security_group.db_sg
  user_data = templatefile("./db/setup_mysql.sh", {
    database_user     = var.database_user,
    database_password = var.database_password,
    database_name     = var.database_name,
    table_name        = var.table_name
  })
  
}



resource "aws_security_group" "db_sg" {
  name        = "db_sg"
  description = "Allow  egress"
  ingress = {
    from_port         = 443
     ip_protocol       = "tcp"
     to_port           = 443
     cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "allow_from_asg" {
  type              = "ingress"
  from_port         = 3306 
  to_port           = 3306 
  protocol          = "tcp"
  source_security_group_id = data.aws_security_group.asg_web_sg.id
  security_group_id = aws_security_group.db_sg.id
}