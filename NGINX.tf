# Desafio Técnico - datacosmos
resource "aws_instance" "nginx" {
  ami           = "ami-0c02fb55956c7d316" # Amazon Linux 2 
  instance_type = "t2.micro"
  key_name      = var.key_name
  subnet_id     = aws_subnet.public_a.id
  user_data     = <<-EOF
                #!/bin/bash
                sudo yum update -y
                sudo amazon-linux-extras enable nginx1
                sudo yum install -y nginx
                sudo systemctl start nginx
                sudo systemctl enable nginx
                EOF

  vpc_security_group_ids = [aws_security_group.nginx_sg.id]

  tags = {
    Name = "nginx-server"
  }
}

# Security Group para NGINX
resource "aws_security_group" "nginx_sg" {
  vpc_id = aws_vpc.default.id # Mesma VPC da Subnet
  name_prefix = "nginx-sg-"

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
    Name = "nginx-security-group"
  }
}

# Output do IP público da instância
output "nginx_instance_public_ip" {
  value = aws_instance.nginx.public_ip
}
