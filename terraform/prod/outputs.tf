
# Obter o DNS do ALB no GitHub Actions
output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = aws_lb.todo-alb.dns_name
}