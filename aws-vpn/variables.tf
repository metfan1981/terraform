variable "region" { default = "us-west-2" }


variable "vpc" {
  type = map(string)
  default = {
    cidr          = "10.90.0.0/16"
    name          = "dh-aws"
    dns_support   = "true"
    dns_hostnames = "false"
    igw_name      = "dh-vpc"
  }
}


variable "dhcp_opt_domain" { default = "example.com" }
variable "dhcp_opt_nameservers" {
  default = ["10.90.55.7", "10.90.67.23"]
}


variable "priv_subnets" {
  type = map(list(string))
  default = {
    cidr = ["10.90.48.0/21", "10.90.64.0/21", "10.90.0.0/21"]
    az   = ["us-west-2a", "us-west-2b", "us-west-2c"]
  }
}
variable "pub_subnets" {
  type = map(list(string))
  default = {
    cidr = ["10.90.32.0/21", "10.90.40.0/21", "10.90.8.0/21"]
    az   = ["us-west-2a", "us-west-2b", "us-west-2c"]
  }
}


variable "sg_main_ingress" {
  type = list(map(string))
  default = [
    {
      cidr_blocks = ""
      self        = true
      description = "all within this SG"
      protocol    = -1
      from_port   = 0
      to_port     = 0
    },
    {
      cidr_blocks = "10.5.0.0/16,10.35.0.0/16,10.25.0.0/23,10.10.10.10/32"
      self        = false
      description = "aggregates"
      protocol    = -1
      from_port   = 0
      to_port     = 0
    },
  ]
}
variable "sg_main_egress" {
  type = list(map(string))
  default = [
    {
      cidr_blocks = "0.0.0.0/0"
      description = ""
      protocol    = -1
      from_port   = 0
      to_port     = 0

    },
  ]
}


variable "vpn" {
  type = map(string)
  default = {
    cgw_name       = "rtr-client"
    client_as      = "10101"
    amazon_as      = "4200010101"
    client_ip      = "200.200.200.69"
    x_conn_cidr    = "169.254.254.0/30"
    ipsec_type     = "ipsec.1"
    startup_action = "start"
  }
}
