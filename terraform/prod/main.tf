# Provider AWS (Reutilizando a variável de região)
provider "aws" {
  region = var.region
}

# --- 1. Rede (VPC, IGW, Subnets Públicas) ---

resource "aws_vpc" "todo-vpc" {
  cidr_block              = "10.1.0.0/16"
  enable_dns_hostnames    = true
  tags = {
    Name = "${var.app_name_todo}-vpc"
  }
}

resource "aws_internet_gateway" "todo-igw" {
  vpc_id = aws_vpc.todo-vpc.id
  tags = {
    Name = "${var.app_name_todo}-igw"
  }
}

data "aws_availability_zones" "az" {
  state = "available"
}

resource "aws_subnet" "todo-public" {
  count                   = 2
  vpc_id                  = aws_vpc.todo-vpc.id
  cidr_block              = cidrsubnet(aws_vpc.todo-vpc.cidr_block, 8, count.index)
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.az.names[count.index]
  tags = {
    Name = "${var.app_name_todo}-public-subnet-${count.index + 1}"
  }
}

resource "aws_route_table" "todo-public-rtb" {
  vpc_id = aws_vpc.todo-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.todo-igw.id
  }
  tags = {
    Name = "${var.app_name_todo}-public-rt"
  }
}

resource "aws_route_table_association" "todo-public-assoc" {
  count          = 2
  subnet_id      = aws_subnet.todo-public[count.index].id
  route_table_id = aws_route_table.todo-public-rtb.id
}

# --- 2. Security Groups ---

resource "aws_security_group" "todo-alb-sg" {
  name   = "${var.app_name_todo}-alb-sg"
  vpc_id = aws_vpc.todo-vpc.id

  # Entrada: HTTP da Internet para o ALB (Porta 80)
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

resource "aws_security_group" "todo-ec2-sg" {
  name   = "${var.app_name_todo}-ec2-sg"
  vpc_id = aws_vpc.todo-vpc.id

  # Permite tráfego do Load Balancer (fonte) na porta 80 (destino/host)
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.todo-alb-sg.id]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- 3. ECR (Container Registry) ---
data "aws_ecr_repository" "todo_ecr" {
  name = var.app_name_todo
}

# --- 4. IAM Roles (CORRIGIDO PARA BUSCAR O PERFIL EXISTENTE) ---

# Buscando o Role de Instância EC2 existente (LabRole)
data "aws_iam_role" "ec2_instance_role_existing" {
  name = "LabRole" 
}

# Corrigido o erro EntityAlreadyExists: 
# Buscamos o perfil da instância com o nome estático, pois ele já existe na AWS
# Recurso: Cria o perfil de instância e o associa ao Role existente.
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${var.app_name_todo}-ec2-instance-profile"
  role = data.aws_iam_role.ec2_instance_role_existing.name
}

# O recurso aws_iam_instance_profile.ec2_instance_profile foi removido
# Se você precisar que o Terraform crie o recurso novamente, primeiro delete ele manualmente na AWS.
# --- 5. EC2 Launch Template (Instala Docker e Roda Container) ---

# Usando o Amazon Linux 2 (otimizado para Docker)
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  owners = ["amazon"]
}

# Script de User Data para configurar o Docker e executar o container
data "template_file" "docker_user_data" {
  template = <<-EOF
    #!/bin/bash
    # Instala Docker e AWS CLI (necessário para login no ECR)
    yum update -y
    yum install -y docker aws-cli
    service docker start
    
    # Habilita o Docker para iniciar com o sistema
    systemctl enable docker
    
    # Variável do Terraform para o URL completo do repositório
    REPO_URL="${data.aws_ecr_repository.todo_ecr.repository_url}"
    
    # Extrai o host do ECR (ex: 123456789012.dkr.ecr.us-east-1.amazonaws.com)
    ECR_HOST=$(echo $REPO_URL | cut -d'/' -f1)
    
    # Configura credenciais do ECR usando o Instance Profile (LabRole)
    aws ecr get-login-password --region ${var.region} |
    docker login --username AWS --password-stdin $ECR_HOST
    
    if [ $? -eq 0 ];
    then
      echo "Login no ECR bem-sucedido."
    # Puxa e executa o container
      # Mapeia a porta do container (${var.container_port}) para a porta 80 do host
      docker run -d \
        --restart=always \
        -p 80:${var.container_port} \
        --name ${var.app_name_todo} \
        $REPO_URL:latest
    else
      echo "Falha ao fazer login no ECR. Verifique as permissões do LabRole."
    fi
  EOF
}

resource "aws_launch_template" "ec2_instance_lt" {
  name_prefix     = "${var.app_name_todo}-ec2-lt-"
  
  image_id        = data.aws_ami.amazon_linux_2.id 
  instance_type   = "t2.micro"
  
  # AQUI USAMOS O NOVO DATA SOURCE PARA O PERFIL DE INSTÂNCIA
  iam_instance_profile {
    arn = aws_iam_instance_profile.ec2_instance_profile.arn
  }
  
  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.todo-ec2-sg.id]
  }

  user_data = base64encode(data.template_file.docker_user_data.rendered)
}

# --- 6. Auto Scaling Group (ASG) ---

resource "aws_autoscaling_group" "ec2_asg" {
  name                 = "${var.app_name_todo}-ec2-asg"
  vpc_zone_identifier  = aws_subnet.todo-public.*.id
  min_size             = 1
  max_size             = 2
  desired_capacity     = 1

  launch_template {
    id      = aws_launch_template.ec2_instance_lt.id
    version = "$Latest"
  }

  # Configura o ASG para anexar as instâncias ao Target Group
  target_group_arns = [aws_lb_target_group.todo_tg.arn]

  tag {
    key                 = "Name"
    value               = "${var.app_name_todo}-web-instance"
    propagate_at_launch = true
  }
}

# --- 7. ALB (Load Balancer) ---

resource "aws_lb" "todo_alb" {
  name               = "${var.app_name_todo}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.todo-alb-sg.id]
  subnets            = aws_subnet.todo-public.*.id
}

resource "aws_lb_target_group" "todo_tg" {
  name     = "${var.app_name_todo}-tg-ec2" 
  # Target Group aponta para a porta 80 do Host
  port     = 80 
  protocol = "HTTP"
  vpc_id   = aws_vpc.todo-vpc.id

  health_check {
    # Assume que seu app tem um endpoint /health
    path                = "/health" 
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
  
  target_type = "instance"
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.todo_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.todo_tg.arn
  }
  
  lifecycle {
    create_before_destroy = true
  }
}