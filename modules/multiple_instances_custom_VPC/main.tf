resource "aws_vpc" "custom-vpc" {
  cidr_block           = var.cidr_vpc
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
  enable_classiclink   = "false"
  instance_tenancy     = "default"

  tags = {
    Name = var.vpc_name
  }
}


resource "aws_subnet" "public-subnet" {
  vpc_id                  = aws_vpc.custom-vpc.id
  cidr_block              = var.cidr_public_subnet
  map_public_ip_on_launch = "true"
  availability_zone       = var.az
}


resource "aws_subnet" "private-subnet" {
  vpc_id                  = aws_vpc.custom-vpc.id
  cidr_block              = var.cidr_private_subnet
  map_public_ip_on_launch = "false"
  availability_zone       = var.az
}


resource "aws_security_group" "pub-ssh-http-allowed" {
  vpc_id = aws_vpc.custom-vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8085
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "80_8080-8085_22_443-allowed"
  }
}


resource "aws_security_group" "priv-from_public_allowed" {
  vpc_id = aws_vpc.custom-vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["${var.cidr_public_subnet}"]
  }

  tags = {
    Name = "all-from-public-allowed"
  }
}


resource "aws_instance" "pub-host" {
  ami                    = var.ami
  count                  = var.public_instance_count
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public-subnet.id
  vpc_security_group_ids = [aws_security_group.pub-ssh-http-allowed.id]
  key_name               = var.ssh_key

  tags = {
    Name = "${var.ec2_pub_name}-${count.index + 1}"
  }
}


resource "aws_instance" "priv-host" {
  ami                    = var.ami
  count                  = var.private_instance_count
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private-subnet.id
  vpc_security_group_ids = [aws_security_group.priv-from_public_allowed.id]
  key_name               = var.ssh_key

  tags = {
    Name = "${var.ec2_priv_name}-${count.index + 1}"
  }
}


resource "aws_nat_gateway" "custom-nat-gw" {
  allocation_id = aws_eip.natgw-eip.id
  subnet_id     = aws_subnet.public-subnet.id
}


resource "aws_eip" "natgw-eip" {
  vpc = true
}


resource "aws_route_table" "route_table_private" {
  vpc_id = aws_vpc.custom-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.custom-nat-gw.id
  }
}


resource "aws_route_table_association" "priv_routes" {
  subnet_id      = aws_subnet.private-subnet.id
  route_table_id = aws_route_table.route_table_private.id
}


resource "aws_internet_gateway" "custom-igw" {
  vpc_id = aws_vpc.custom-vpc.id
}


resource "aws_route_table" "route_table_public" {
  vpc_id = aws_vpc.custom-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.custom-igw.id
  }
}


resource "aws_route_table_association" "pub_routes" {
  subnet_id      = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.route_table_public.id
}



