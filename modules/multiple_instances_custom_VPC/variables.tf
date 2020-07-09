# custom-vpc
variable "cidr_vpc" { type = string }
variable "vpc_name" { type = string }

# public-subnet
variable "cidr_public_subnet" { type = string }

# private-subnet
variable "cidr_private_subnet" { type = string }

# pub-host (EC2 public)
variable "ec2_pub_name" { type = string }
variable "public_instance_count" { type = number }

# priv-host (EC2 private)
variable "ec2_priv_name" { type = string }
variable "private_instance_count" { type = number }

# Common 
variable "az" { type = string }
variable "instance_type" { type = string }
variable "ami" { type = string }
variable "ssh_key" { type = string }