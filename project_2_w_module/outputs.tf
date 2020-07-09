output "public_ip_assigned" {
  description = "Public IP addresses of EC2 instances"
  value       = [module.multiple_instances_custom_VPC.pub-host[0].public_ip]
}
