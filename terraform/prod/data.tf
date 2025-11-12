data "aws_instances" "asg_instances" {
  instance_state_names = ["running"]
  filter {
    name   = "tag:aws:autoscaling:groupName"
    # CORRIGIDO: Referenciando aws_autoscaling_group.ec2_asg
    values = [aws_autoscaling_group.ec2_asg.name] 
  }
}