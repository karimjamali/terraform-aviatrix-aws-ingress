output "lb_dns_name" {
  value = aws_lb.centralized_ingress_lb.dns_name
}