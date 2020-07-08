output "elastic_IPs_assigned" {
  description = "Public IP addresses of EC2 instances"
  value       = [aws_eip.eip.*.public_ip]
}
