
provider "aws" {
  region = "us-east-1"
}

# 1. Configuração de Rede (VPC e Subnets)
# ==============================================================================

resource "aws_vpc" "todo-vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "${var.app_name}-vpc"
  }
}

resource "aws_internet_gateway" "todo-igw" {
  vpc_id = aws_vpc.todo-vpc.id
  tags = {
    Name = "${var.app_name}-igw"
  }
}

# Subnets Públicas (para ALB e EC2)
resource "aws_subnet" "todo-public" {
  count             = 2 
  vpc_id            = aws_vpc.todo-vpc.id
  cidr_block        = cidrsubnet(aws_vpc.todo-vpc.cidr_block, 8, count.index)
  map_public_ip_on_launch = true # Para as EC2 receberem IP Público
  availability_zone = data.aws_availability_zones.az.names[count.index]

  tags = {
    Name = "${var.app_name}-public-subnet-${count.index + 1}"
  }
}

data "aws_availability_zones" "az" {
  state = "available"
}

# Tabela de Rotas para Internet
resource "aws_route_table" "todo-public-rtb" {
  vpc_id = aws_vpc.todo-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.todo-igw.id
  }

  tags = {
    Name = "${var.app_name}-public-rt"
  }
}

# Associa a Tabela de Rotas às Subnets Públicas
resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.todo-public[count.index].id
  route_table_id = aws_route_table.todo-public-rtb.id
}

# 2. Security Groups
# ==============================================================================

# SG para o ALB (Permite tráfego HTTP/S de qualquer lugar)
resource "aws_security_group" "alb-sg" {
  name        = "${var.app_name}-alb-sg"
  vpc_id      = aws_vpc.todo-vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# SG para as EC2 (Permite acesso do ALB e SSH/Ansible)
resource "aws_security_group" "todo-sg" {
  name        = "${var.app_name}-ec2-sg"
  vpc_id      = aws_vpc.todo-vpc.id

  # Permite acesso HTTP (porta 8000/Gunicorn) *somente* do ALB
  ingress {
    from_port       = 8000 # Porta que o Gunicorn/Aplicação vai escutar
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb-sg.id]
  }

  # Permite acesso SSH/Ansible (Porta 22)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 3. Application Load Balancer (ALB)
# ==============================================================================

resource "aws_lb" "todo-alb" {
  name               = "${var.app_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb-sg.id]
  subnets            = aws_subnet.todo-public.*.id

  enable_deletion_protection = false

  tags = {
    Name = "${var.app_name}-alb"
  }
}

resource "aws_lb_target_group" "todo-tg" {
  name     = "${var.app_name}-tg"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = aws_vpc.todo-vpc.id

  health_check {
    path = "/health"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.todo-alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.todo-tg.arn
  }
}

# 4. EC2 e Auto Scaling Group (ASG)
# ==============================================================================

resource "aws_launch_template" "todo-lt" {
  name_prefix     = "${var.app_name}-lt-"
  image_id        = var.ami_id
  instance_type   = "t3.micro"
  key_name        = var.key_name
  vpc_security_group_ids = [aws_security_group.todo-sg.id]
  metadata_options {
    http_endpoint = "enabled"
  }

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = 8
      volume_type = "gp2"
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.app_name}-ec2"
    }
  }
}

resource "aws_autoscaling_group" "todo-asg" {
  name                        = "${var.app_name}-asg"
  vpc_zone_identifier         = aws_subnet.todo-public.*.id
  target_group_arns           = [aws_lb_target_group.todo-tg.arn]
  health_check_type           = "ELB"
  health_check_grace_period = 300 # Segundos

  min_size = 1 # Capacidade Mínima
  max_size = 2 # Capacidade Máxima
  desired_capacity = 1 # Quantidade de instâncias que queremos rodando

  launch_template {
    id      = aws_launch_template.todo-lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.app_name}-instance"
    propagate_at_launch = true
  }
}

# POLÍTICA DE ESCALA
# ==============================================================================

resource "aws_autoscaling_policy" "cpu_scale_up" {
  name                   = "${var.app_name}-cpu-scale-up"
  autoscaling_group_name = aws_autoscaling_group.todo-asg.name
  policy_type            = "TargetTrackingScaling"
  estimated_instance_warmup = 180

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    # Escala para manter a utilização média de CPU em 70%
    target_value = 70.0
  }
}
