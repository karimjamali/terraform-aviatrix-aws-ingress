output "lb_dns_name" {
  value = aws_lb.centralized_ingress_lb.dns_name
}

output "lb_sg_id" {
  value = module.security_group_centralized_lb.this_security_group_id
}
