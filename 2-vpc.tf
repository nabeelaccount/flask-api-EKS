resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/19"

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.env}-${var.name}"
  }
}