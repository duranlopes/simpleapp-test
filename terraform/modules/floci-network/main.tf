resource "aws_vpc" "this" {
  cidr_block           = "10.42.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.cluster_name}-vpc"
  }
}

resource "aws_subnet" "private" {
  count = 2

  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.42.${count.index + 1}.0/24"
  availability_zone = "${var.region}${count.index == 0 ? "a" : "b"}"

  tags = {
    Name = "${var.cluster_name}-private-${count.index + 1}"
  }
}

resource "aws_security_group" "cluster" {
  name        = "${var.cluster_name}-cluster"
  description = "Floci EKS test cluster security group"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "${var.cluster_name}-cluster"
  }
}
