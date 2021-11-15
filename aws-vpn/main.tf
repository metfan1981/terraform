terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}


provider "aws" {
  profile = "default"
  region  = var.region
}


################################################################################
# VPC / DHCP / Default IGW
################################################################################


resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc.cidr
  enable_dns_support   = var.vpc.dns_support
  enable_dns_hostnames = var.vpc.dns_hostnames
  tags = {
    Name = var.vpc.name
  }
}


resource "aws_vpc_dhcp_options" "dhcp" {
  domain_name         = var.dhcp_opt_domain
  domain_name_servers = var.dhcp_opt_nameservers
  tags = {
    Name = "${var.vpc.name}-vpc-nat-dhcp"
  }
}


resource "aws_vpc_dhcp_options_association" "dhcp" {
  vpc_id          = aws_vpc.vpc.id
  dhcp_options_id = aws_vpc_dhcp_options.dhcp.id
}


resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = var.vpc.igw_name
  }
}


################################################################################
# Route Tables
################################################################################


resource "aws_route_table" "default" {
  vpc_id = aws_vpc.vpc.id
}


resource "aws_route" "default" {
  route_table_id         = aws_route_table.default.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id

  depends_on = [aws_internet_gateway.igw, aws_route_table.default]
}


resource "aws_main_route_table_association" "default" {
  vpc_id         = aws_vpc.vpc.id
  route_table_id = aws_route_table.default.id
}


resource "aws_route_table" "private" {
  count  = length(var.priv_subnets.cidr)
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "rt-dh-aws-${element(var.priv_subnets.az, count.index)}-nat"
  }
}


resource "aws_route" "private" {
  count                  = length(var.priv_subnets.cidr)
  route_table_id         = element(aws_route_table.private.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = element(aws_nat_gateway.nat.*.id, count.index)

  depends_on = [aws_route_table.private, aws_nat_gateway.nat]
}


resource "aws_route_table_association" "private" {
  count          = length(var.priv_subnets.cidr)
  subnet_id      = element(aws_subnet.priv_subnets.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)

  depends_on = [aws_route.private, aws_subnet.priv_subnets]
}


resource "aws_route_table" "public" {
  count  = length(var.pub_subnets.cidr)
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "rt-dh-aws-${element(var.pub_subnets.az, count.index)}-public"
  }
}


resource "aws_route" "public" {
  count                  = length(var.pub_subnets.cidr)
  route_table_id         = element(aws_route_table.public.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id

  depends_on = [aws_route_table.public]
}


resource "aws_route_table_association" "public" {
  count          = length(var.pub_subnets.cidr)
  subnet_id      = element(aws_subnet.pub_subnets.*.id, count.index)
  route_table_id = element(aws_route_table.public.*.id, count.index)

  depends_on = [aws_route.public, aws_subnet.pub_subnets]
}


################################################################################
# Subnets
################################################################################


resource "aws_subnet" "priv_subnets" {
  count                           = length(var.priv_subnets.cidr)
  vpc_id                          = aws_vpc.vpc.id
  cidr_block                      = element(var.priv_subnets.cidr, count.index)
  availability_zone               = element(var.priv_subnets.az, count.index)
  map_public_ip_on_launch         = false
  assign_ipv6_address_on_creation = false

  timeouts {
    create = "3m"
  }

  tags = {
    Name = "${var.vpc.name}-${element(var.priv_subnets.az, count.index)}-nat"
  }
}


resource "aws_subnet" "pub_subnets" {
  count                           = length(var.pub_subnets.cidr)
  vpc_id                          = aws_vpc.vpc.id
  cidr_block                      = element(var.pub_subnets.cidr, count.index)
  availability_zone               = element(var.pub_subnets.az, count.index)
  map_public_ip_on_launch         = true
  assign_ipv6_address_on_creation = false

  timeouts {
    create = "3m"
  }

  tags = {
    Name = "${var.vpc.name}-${element(var.priv_subnets.az, count.index)}-public"
  }
}


################################################################################
# EIP / NAT GW
################################################################################


resource "aws_eip" "nat" {
  count = length(var.pub_subnets.cidr)
  vpc   = true
}


resource "aws_nat_gateway" "nat" {
  count             = length(var.pub_subnets.cidr)
  allocation_id     = element(aws_eip.nat.*.id, count.index)
  subnet_id         = element(aws_subnet.pub_subnets.*.id, count.index)
  connectivity_type = "public"

  tags = {
    Name = "nat-dh-aws-${element(var.pub_subnets.az, count.index)}"
  }

  depends_on = [aws_eip.nat]
}


################################################################################
# Default Security Group
################################################################################


resource "aws_security_group" "default" {
  name   = "${var.vpc.name}-sg"
  vpc_id = aws_vpc.vpc.id

  dynamic "ingress" {
    for_each = var.sg_main_ingress
    content {
      cidr_blocks = compact(split(",", lookup(ingress.value, "cidr_blocks", "")))
      self        = lookup(ingress.value, "self", false)
      description = ingress.value.description
      protocol    = ingress.value.protocol
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
    }
  }

  dynamic "egress" {
    for_each = var.sg_main_egress
    content {
      cidr_blocks = compact(split(",", lookup(egress.value, "cidr_blocks", "")))
      description = egress.value.description
      protocol    = egress.value.protocol
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
    }
  }

  timeouts {
    create = "3m"
  }

  tags = {
    Name = "${var.vpc.name}-sg"
  }
}


################################################################################
# VPN
################################################################################


resource "aws_customer_gateway" "main" {
  bgp_asn    = var.vpn.client_as
  ip_address = var.vpn.client_ip
  type       = lookup(var.vpn, "ipsec_type", "ipsec.1")

  tags = {
    Name = var.vpn.cgw_name
  }
}


resource "aws_vpn_gateway" "main" {
  vpc_id          = aws_vpc.vpc.id
  amazon_side_asn = var.vpn.amazon_as

  tags = {
    Name = "${var.vpn.cgw_name}-vgw"
  }

  depends_on = [aws_customer_gateway.main]
}


resource "aws_vpn_connection" "main" {
  vpn_gateway_id         = aws_vpn_gateway.main.id
  customer_gateway_id    = aws_customer_gateway.main.id
  static_routes_only     = false
  tunnel1_inside_cidr    = var.vpn.x_conn_cidr
  type                   = lookup(var.vpn, "ipsec_type", "ipsec.1")
  tunnel1_startup_action = lookup(var.vpn, "startup_action", "start")

  tags = {
    Name = "${var.vpn.cgw_name}-vpn"
  }

  depends_on = [aws_vpn_gateway.main]
}


resource "aws_vpn_gateway_route_propagation" "private" {
  count          = length(var.priv_subnets.cidr)
  route_table_id = element(aws_route_table.private.*.id, count.index)
  vpn_gateway_id = aws_vpn_gateway.main.id
}
