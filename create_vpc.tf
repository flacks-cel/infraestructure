# Criação da VPC principal Desafio Técnico - datacosmos

resource "aws_vpc" "main" {
  cidr_block           = "172.31.0.0/16"
  instance_tenancy     = "default" # Alterado para default, mais econômico
  enable_dns_support   = true      # Habilita suporte a DNS
  enable_dns_hostnames = true      # Habilita nomes DNS para instâncias

  tags = {
    Name        = "Main-VPC"
    Environment = "Dev"
    ManagedBy   = "Terraform"
  }
}

# Criar um Internet Gateway para conectar a VPC à Internet
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Main-Internet-Gateway"
  }
}

# Criar uma Tabela de Rotas para a VPC
resource "aws_route_table" "main_route_table" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Main-Route-Table"
  }
}

# Adicionar uma rota para o Internet Gateway
resource "aws_route" "main_route" {
  route_table_id         = aws_route_table.main_route_table.id
  destination_cidr_block = "0.0.0.0/0" # Permite tráfego para a Internet
  gateway_id             = aws_internet_gateway.main_igw.id
}

# Associar a tabela de rotas a uma Subnet Pública
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "172.31.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true # Garante que instâncias recebem IP público

  tags = {
    Name        = "Public-Subnet"
    Environment = "Dev"
  }
}

resource "aws_route_table_association" "main_route_table_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.main_route_table.id
}
