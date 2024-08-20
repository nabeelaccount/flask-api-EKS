##########################################################################################
# EKS 
##########################################################################################

resource "aws_subnet" "private_zone1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = var.zone1

  tags = {
    "Name"                                             = "${var.env}-private-${var.zone1}"
    "kubernetes.io/role/internal-elb"                  = "1"
    "kubernetes.io/cluster/${var.env}-${var.eks_name}" = "owned"
  }
}

resource "aws_subnet" "private_zone2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = var.zone2

  tags = {
    "Name"                                             = "${var.env}-private-${var.zone2}"
    "kubernetes.io/role/internal-elb"                  = "1"
    "kubernetes.io/cluster/${var.env}-${var.eks_name}" = "owned"
  }
}

resource "aws_subnet" "private_zone3" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = var.zone2

  tags = {
    "Name"                                             = "${var.env}-private-${var.zone3}"
    "kubernetes.io/role/internal-elb"                  = "1"
    "kubernetes.io/cluster/${var.env}-${var.eks_name}" = "owned"
  }
}

resource "aws_subnet" "public_zone1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = var.zone1
  map_public_ip_on_launch = true

  tags = {
    "Name"                                             = "${var.env}-public-${var.zone1}"
    "kubernetes.io/role/elb"                           = "1"
    "kubernetes.io/cluster/${var.env}-${var.eks_name}" = "owned"
  }
}

resource "aws_subnet" "public_zone2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = var.zone2
  map_public_ip_on_launch = true

  tags = {
    "Name"                                             = "${var.env}-public-${var.zone2}"
    "kubernetes.io/role/elb"                           = "1"
    "kubernetes.io/cluster/${var.env}-${var.eks_name}" = "owned"
  }
}

resource "aws_subnet" "public_zone3" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.5.0/24"
  availability_zone       = var.zone2
  map_public_ip_on_launch = true

  tags = {
    "Name"                                             = "${var.env}-public-${var.zone3}"
    "kubernetes.io/role/elb"                           = "1"
    "kubernetes.io/cluster/${var.env}-${var.eks_name}" = "owned"
  }
}

##########################################################################################
# RDS
##########################################################################################
resource "aws_subnet" "rds_zone1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.6.0/24"
  availability_zone = var.zone1

  tags = {
    "Name"                                             = "${var.env}-private-${var.zone1}"
  }
}

resource "aws_subnet" "rds_zone2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.7.0/24"
  availability_zone = var.zone2

  tags = {
    "Name"                                             = "${var.env}-private-${var.zone2}"
  }
}

resource "aws_subnet" "rds_zone3" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.8.0/24"
  availability_zone = var.zone3

  tags = {
    "Name"                                             = "${var.env}-private-${var.zone3}"
  }
}