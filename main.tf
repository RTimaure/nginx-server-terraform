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

    # VINCULACIÓN: Aquí solucionamos el error api error VPCIdNotSpecified
    subnet_id     = aws_subnet.public_subnet.id
    tags = {
        Name = "nginx-server-terraform"
  }
} 