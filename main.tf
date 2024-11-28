provider "aws" {
  region = "us-east-1"
}

# Variáveis para maior flexibilidade
variable "key_name" {
  default = "grupo01"
}

variable "allowed_ssh_ip" {
  default = "0.0.0.0/0" # Defina o IP autorizado para SSH
}

# Instância EC2
resource "aws_instance" "web" {
  ami           = "ami-0c02fb55956c7d316" # Amazon Linux 2 AMI
  instance_type = "t2.micro"
  key_name      = var.key_name
  user_data     = file("user_data.sh")
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  subnet_id     = aws_subnet.public_a.id

  tags = {
    Name = "apache-php-mysql-server"
  }
}

# Security Group para EC2
resource "aws_security_group" "web_sg" {
  vpc_id = aws_vpc.default.id # Assegura que o SG está na mesma VPC
  name_prefix = "web-sg-"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2-web-security-group"
  }
}

# Criar Subnets Públicas e Privadas
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.default.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-a"
  }
}

resource "aws_subnet" "private_a" {
  vpc_id                  = aws_vpc.default.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "private-subnet-a"
  }
}

# Nova subnet privada em outra AZ
resource "aws_subnet" "private_b" {
  vpc_id                  = aws_vpc.default.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false

  tags = {
    Name = "private-subnet-b"
  }
}

# Security Group para o RDS
resource "aws_security_group" "rds_sg" {
  vpc_id = aws_vpc.default.id # Certifique-se de que está na mesma VPC do RDS

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # Permite tráfego interno na VPC
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-security-group"
  }
}

# RDS PostgreSQL
resource "aws_db_instance" "postgresql" {
  allocated_storage      = 20
  engine                 = "postgres"
  engine_version         = "11.22"
  instance_class         = "db.t3.micro"
  username               = "grupo01"
  password               = "grupo01!"
  publicly_accessible    = false
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.default.name

  tags = {
    Name = "terraform-postgres-rds"
  }
}

# Grupo de Subnets para o RDS
resource "aws_db_subnet_group" "default" {
  name       = "default-db-subnet-group"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  tags = {
    Name = "default-db-subnet-group"
  }
}

# Configuração da VPC
resource "aws_vpc" "default" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "default-vpc"
  }
}

# Criar Internet Gateway
resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id
  tags = {
    Name = "default-internet-gateway"
  }
}

# Criar Tabela de Rotas para Subnets Públicas
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.default.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.default.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# Associar a Tabela de Rotas à Subnet Pública
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}
