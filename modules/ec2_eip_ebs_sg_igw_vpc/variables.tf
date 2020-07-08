# EC2
variable "ec2_name" { type = string }
variable "ami" { type = string }
variable "ssh_key" { type = string }
variable "instance_count" { type = number }
variable "instance_type" { type = string }
variable "eip_name" { type = string }

# EBS
variable "ebs_name" { type = string }
variable "size" { type = number }

# VPC
variable "cidr_vpc" { type = string }
variable "vpc_name" { type = string }
variable "igw_name" { type = string }
variable "az" { type = string }

# Subnet
variable "cidr_subnet" { type = string }
variable "subnet_name" { type = string }
variable "route_table_name" { type = string }

# Security group
variable "sg_name" { type = string }
variable "egress_rule" { type = list }
variable "ingress_rule" { type = list }
variable "port_1" { type = number }
variable "port_1_protocol" { type = string }
variable "port_2" { type = number }
variable "port_2_protocol" { type = string }
