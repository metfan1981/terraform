provider "aws" {
  profile = "default"
  region  = "eu-central-1"
}

module "multiple_instances_custom_VPC" {

  source = "../modules/multiple_instances_custom_VPC"

  #VPC
  cidr_vpc = "10.10.0.0/16"
  vpc_name = "my-own-vpc"

  #Subnet Public 
  cidr_public_subnet = "10.10.50.0/24"

  #Subnet Private 
  cidr_private_subnet = "10.10.99.0/24"

  #EC2 Public
  ec2_pub_name          = "pub-host"
  public_instance_count = 2

  #EC2 Private
  ec2_priv_name          = "priv-host"
  private_instance_count = 1

  #EC2 Common
  instance_type = "t2.micro"
  ami           = "ami-0d359437d1756caa8"
  ssh_key       = "awskey"
  az            = "eu-central-1b"

}
