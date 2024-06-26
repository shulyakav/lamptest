resource "random_password" "master"{
  length           = 25
  special          = true
  min_special      = 5
  override_special = "()*$%^"
}

resource "aws_secretsmanager_secret" "password" {
  name = "mysql777-cluster-password"
}

resource "aws_secretsmanager_secret_version" "password" {
  secret_id = aws_secretsmanager_secret.password.id
  secret_string = random_password.master.result
  lifecycle {
    ignore_changes = [secret_string, ]
  }
}