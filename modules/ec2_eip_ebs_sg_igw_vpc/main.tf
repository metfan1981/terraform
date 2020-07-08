resource "aws_vpc" "neteng-vpc" {
  cidr_block           = var.cidr_vpc
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
  enable_classiclink   = "false"
  instance_tenancy     = "default"

  tags = {
    Name = var.vpc_name
  }
}

resource "aws_internet_gateway" "neteng-igw-1" {
  vpc_id = aws_vpc.neteng-vpc.id
  tags = {
    Name = var.igw_name
  }
}

resource "aws_subnet" "neteng-subnet-1" {
  vpc_id                  = aws_vpc.neteng-vpc.id
  cidr_block              = var.cidr_subnet
  map_public_ip_on_launch = "true"
  availability_zone       = var.az
  depends_on              = [aws_internet_gateway.neteng-igw-1]
  tags = {
    Name = var.subnet_name
  }
}

resource "aws_route_table" "routes" {
  vpc_id = aws_vpc.neteng-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.neteng-igw-1.id
  }

  tags = {
    Name = var.route_table_name
  }
}

resource "aws_route_table_association" "routes-neteng-subnet-1" {
  subnet_id      = aws_subnet.neteng-subnet-1.id
  route_table_id = aws_route_table.routes.id
}

resource "aws_security_group" "ssh-http-allowed" {
  vpc_id = aws_vpc.neteng-vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = var.egress_rule
  }
  ingress {
    from_port   = var.port_1
    to_port     = var.port_1
    protocol    = var.port_1_protocol
    cidr_blocks = var.ingress_rule
  }

  ingress {
    from_port   = var.port_2
    to_port     = var.port_2
    protocol    = var.port_2_protocol
    cidr_blocks = var.ingress_rule
  }
  tags = {
    Name = var.sg_name
  }
}

resource "aws_ebs_volume" "neteng-disk" {
  availability_zone = var.az
  size              = var.size
  count             = var.instance_count

  tags = {
    Name = "${var.ebs_name}-${count.index + 1}"
  }
}

resource "aws_instance" "web" {
  ami                    = var.ami
  count                  = var.instance_count
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.neteng-subnet-1.id
  vpc_security_group_ids = [aws_security_group.ssh-http-allowed.id]
  key_name               = var.ssh_key

  tags = {
    Name = "${var.ec2_name}-${count.index + 1}"
  }
}

resource "aws_eip" "eip" {
  vpc        = true
  count      = var.instance_count
  instance   = element(aws_instance.web.*.id, count.index)
  depends_on = [aws_internet_gateway.neteng-igw-1]

  tags = {
    Name = "${var.eip_name}-${count.index + 1}"
  }
}

resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  count       = var.instance_count
  volume_id   = element(aws_ebs_volume.neteng-disk.*.id, count.index)
  instance_id = element(aws_instance.web.*.id, count.index)
}
