data "aws_security_group" "cluster" {
  id = data.aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id
}

# output "EKS-SG" {
#   value = data.aws_security_group.cluster.id
# }


# Modify EKS Security group to Allow traffic from RDS subnets
resource "aws_security_group_rule" "allow_rds_to_eks" {
  type                     = "ingress"
  from_port                = 1024
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = data.aws_security_group.cluster.id
  cidr_blocks              = [
    aws_subnet.rds_zone1.cidr_block,
    aws_subnet.rds_zone2.cidr_block,
    aws_subnet.rds_zone3.cidr_block,
  ]
}

resource "aws_security_group_rule" "allow_eks_to_rds" {
  type                     = "egress"
  from_port                = 1024
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = data.aws_security_group.cluster.id
  cidr_blocks              = [
    aws_subnet.rds_zone1.cidr_block,
    aws_subnet.rds_zone2.cidr_block,
    aws_subnet.rds_zone3.cidr_block,
  ]
}

# Create RDS Security group
resource "aws_security_group" "rds_sg" {
  name        = "${var.env}-${var.name}-rds-sg"
  vpc_id      = aws_vpc.main.id
  description = "Security group for RDS"

  ingress {
    from_port   = 1024
    to_port     = 65535
    protocol    = "tcp"
    security_groups = [
      data.aws_security_group.cluster.id,
    ]
  }

  egress {
    from_port   = 1024
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [
      aws_subnet.private_zone1.cidr_block,
      aws_subnet.private_zone2.cidr_block,
      aws_subnet.private_zone3.cidr_block,
    ]
  }

  tags = {
    Name = "${var.env}-${var.name}-rds-sg"
  }
}
