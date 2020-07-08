variable "region" { default = "eu-central-1" }

# EC2
variable "ami" { default = "ami-05ed2c1359acd8af6" }
variable "ssh_key" { default = "awskey" }
variable "instance_count" { default = "2" }
variable "instance_type" { default = "t2.micro" }

# EBS
variable "size" { default = "5" }

# VPC
variable "cidr_vpc" { default = "10.0.0.0/16" }

# Subnet
variable "cidr_subnet" { default = "10.0.10.0/24" }

# Security group
variable "egress_rule" { default = ["0.0.0.0/0"] }
variable "ingress_rule" { default = ["0.0.0.0/0"] }
