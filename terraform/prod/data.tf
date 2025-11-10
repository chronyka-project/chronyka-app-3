data "aws_instances" "asg_instances" {
  instance_state_names = ["running"]
  filter {
    name   = "tag:aws:autoscaling:groupName"
    values = [aws_autoscaling_group.todo-asg.name]
  }
}