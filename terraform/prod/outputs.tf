output "alb_dns_name_todo" {
  description = "O nome DNS do Application Load Balancer do Todo App"
  value       = aws_lb.todo_alb.dns_name
}