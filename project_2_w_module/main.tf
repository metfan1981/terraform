provider "aws" {
  profile = "default"
  region  = "eu-central-1"
}

module "full_build" {
  source = "../modules/ec2_eip_ebs_sg_igw_vpc"

  # VPC
  cidr_vpc         = "10.0.0.0/16"
  vpc_name         = "neteng-vpc"
  igw_name         = "neteng-igw-1"
  route_table_name = "routes"

  # Subnet
  cidr_subnet = "10.0.10.0/24"
  az          = "eu-central-1b"
  subnet_name = "neteng-subnet-1"

  # Security Group
  sg_name         = "ssh-http-allowed"
  egress_rule     = ["0.0.0.0/0"]
  ingress_rule    = ["0.0.0.0/0"]
  port_1          = 22
  port_1_protocol = "tcp"
  port_2          = 80
  port_2_protocol = "tcp"

  # EBS
  ebs_name = "neteng-disk"
  size     = 5

  # EC2
  ec2_name       = "web"
  ami            = "ami-05ed2c1359acd8af6"
  instance_count = 2
  instance_type  = "t2.micro"
  ssh_key        = "awskey"
  eip_name       = "eip"
}
