########## PROVIDER ##########
provider "aws" {
    region = "us-east-1"
}

########## NETWORK ##########
# 1. Creamos la red virtual (VPC)
resource "aws_vpc" "main_vpc" {
    cidr_block           = "10.0.0.0/16"
    enable_dns_hostnames = true
    tags = {
        Name = "vpc-terraform-lab"
  }
}

# 2. Creamos una subred donde vivirá la instancia
resource "aws_subnet" "public_subnet" {
    vpc_id            = aws_vpc.main_vpc.id
    cidr_block        = "10.0.1.0/24"
    availability_zone = "us-east-1a" # Asegúrate que coincida con tu región
    map_public_ip_on_launch = true # Asigna IP pública automáticamente a las instancias en esta subred
    tags = {
        Name = "subnet-public-1"
  }
}

# 3. Puerta de enlace para que la VPC tenga salida a Internet
resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.main_vpc.id
}

########## RESOURCES ##########
resource "aws_instance" "nginx_server2" {
    ami = "ami-0440d3b780d96b29d"
    instance_type = "t3.micro"
    subnet_id     = aws_subnet.public_subnet.id
    associate_public_ip_address = true  #   Asegura que la instancia tenga una IP pública para acceder a ella desde Internet
    # Instalamos nginx usando user_data para que se ejecute al iniciar la instancia
    user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install nginx -y
                sudo systemctl start nginx
                sudo systemctl enable nginx
            EOF
    key_name = aws_key_pair.nginx-server-ssh.key_name

    vpc_security_group_ids = [
        aws_security_group.nginx-server-sg.id
     ]

    # VINCULACIÓN: Aquí solucionamos el error api error VPCIdNotSpecified

    tags = {
        Name = "nginx-server-terraform"
  }
} 

# Crear la tabla de rutas
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# Asociar la tabla de rutas con la subred
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# Crear un par de claves para SSH 
resource "aws_key_pair" "nginx-server-ssh" {
    key_name   = "nginx-server-ssh"
    public_key = file("nginx-server.key.pub")
}

# Crear un grupo de seguridad para permitir tráfico HTTP y SSH
resource "aws_security_group" "nginx-server-sg" {
    name        = "nginx-server-sg"
    description = "Allow HTTP and SSH traffic"
    vpc_id      = aws_vpc.main_vpc.id

    # El bloque de ingress define las reglas de entrada para el grupo de seguridad
    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        # 0.0.0.0/0" significa que se permite el tráfico desde cualquier dirección IP
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    #El bloque de egress define las reglas de salida para el grupo de seguridad
    egress {
        # El bloque de egress permite todo el tráfico saliente
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]

    }
}