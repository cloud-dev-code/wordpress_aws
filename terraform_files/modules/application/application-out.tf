output "alb_dns" {
  value  = aws_lb.wordpress-loadbalancer.dns_name
}
