# # db: https://dev.to/aws-builders/how-to-launch-an-rds-cluster-with-multi-az-read-replica-using-terraform-2ca1
# # secret manager: https://stackoverflow.com/questions/65603923/terraform-rds-database-credentials


# ########################################################################
# # Create security Group Password
# ########################################################################
# resource "aws_security_group" "postgres" {
#   name        = "allow_postgres"
#   description = "Allow Postgres traffic"
#   vpc_id      = aws_vpc.main.id

#   ingress {
#     description = "allow Postgres"
#     from_port   = 5432
#     to_port     = 5432
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]   # Can be restricted to only SG of the EKS nodes
#   }

#   egress {
#     from_port        = 0
#     to_port          = 0
#     protocol         = "-1"
#     cidr_blocks      = ["0.0.0.0/0"]
#     ipv6_cidr_blocks = ["::/0"]
#   }

#   tags = {
#     Name = "allow postgres"
#   }
# }


########################################################################
# Create Password and store in Secret Manager
########################################################################
resource "random_password" "master" {
  length           = 16
  special          = true
  override_special = "_!%^"
}

resource "aws_secretsmanager_secret" "password" {
  name = "postgres-secrets-five"
}

resource "aws_secretsmanager_secret_version" "password" {
  secret_id = aws_secretsmanager_secret.password.id
  secret_string = jsonencode({
    username = "postgres"
    password = random_password.master.result
  })
}


# ########################################################################
# # Retrive Password from Secret Manager
# ########################################################################
# data "aws_secretsmanager_secret" "db_credentials" {
#   name = aws_secretsmanager_secret.password.name
# }

# data "aws_secretsmanager_secret_version" "db_credentials_version" {
#   secret_id = data.aws_secretsmanager_secret.db_credentials.id
# }

# locals {
#   db_credentials = jsondecode(data.aws_secretsmanager_secret_version.db_credentials_version.secret_string)
# }


# # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group
# resource "aws_db_subnet_group" "postgres" {
#   name       = "postgres-subnet-group"
#   description = "Postgres database subnet cluster"
#   subnet_ids = [aws_subnet.rds_zone1.id, aws_subnet.rds_zone2.id, aws_subnet.rds_zone3.id]

#   tags = {
#     Name = "Postgres DB Subnet Group"
#   }
# }

# ########################################################################
# # Create Postgres Server Cluster
# ########################################################################
# resource "aws_rds_cluster" "postgres" {
#   cluster_identifier      = "${var.name}-database"
#   engine                  = "aurora-postgresql"
#   database_name           = "transactional"
#   master_username         = "postgres"
#   availability_zones      = [var.zone1, var.zone2, var.zone3]
#   master_password         = local.db_credentials["password"]
#   vpc_security_group_ids  = [aws_security_group.postgres.id]
#   storage_encrypted       = true
#   skip_final_snapshot     = true 
#   db_subnet_group_name    = aws_db_subnet_group.postgres.name 
# }

# resource "aws_rds_cluster_instance" "postgres" {
#   count = 1
#   identifier         = "${var.name}-database${count.index}"
#   cluster_identifier = aws_rds_cluster.postgres.id
#   publicly_accessible = true
#   instance_class     = "db.t3.medium"
#   engine             = aws_rds_cluster.postgres.engine
#   engine_version     = aws_rds_cluster.postgres.engine_version            
# }