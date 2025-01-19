# Definición de la VPC
resource "aws_vpc" "Cloud9_vpc" {
  cidr_block           = "172.16.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "Cloud9-VPC"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "Cloud9_igw" {
  vpc_id = aws_vpc.Cloud9_vpc.id

  tags = {
    Name = "Cloud9-InternetGateway"
  }
}

# Elastic IP para NAT Gateway
resource "aws_eip" "Cloud9_nat_eip" {
  domain = "vpc"
}

# NAT Gateway
resource "aws_nat_gateway" "Cloud9_nat_gateway" {
  allocation_id = aws_eip.Cloud9_nat_eip.id
  subnet_id     = aws_subnet.Cloud9_public_subnet_1.id
  tags = {
    Name = "Cloud9-NAT-Gateway"
  }
}

# Route Table Pública (Internet Gateway)
resource "aws_route_table" "Cloud9_public_rt" {
  vpc_id = aws_vpc.Cloud9_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Cloud9_igw.id
  }

  tags = {
    Name = "Cloud9-Public-RouteTable"
  }
}

# Route Table Privada 1 (NAT Gateway)
resource "aws_route_table" "Cloud9_private_rt_1" {
  vpc_id = aws_vpc.Cloud9_vpc.id

  route {
    cidr_block    = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.Cloud9_nat_gateway.id
  }

  tags = {
    Name = "Cloud9-Private-RouteTable-1"
  }
}

# Route Table Privada 2 (NAT Gateway)
resource "aws_route_table" "Cloud9_private_rt_2" {
  vpc_id = aws_vpc.Cloud9_vpc.id

  route {
    cidr_block    = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.Cloud9_nat_gateway.id
  }

  tags = {
    Name = "Cloud9-Private-RouteTable-2"
  }
}

# Subnets Públicas
resource "aws_subnet" "Cloud9_public_subnet_1" {
  vpc_id                  = aws_vpc.Cloud9_vpc.id
  cidr_block              = "172.16.0.0/19"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Cloud9-Public-Subnet-1"
  }
}

resource "aws_subnet" "Cloud9_public_subnet_2" {
  vpc_id                  = aws_vpc.Cloud9_vpc.id
  cidr_block              = "172.16.32.0/19"
  availability_zone       = "us-east-1c"
  map_public_ip_on_launch = true

  tags = {
    Name = "Cloud9-Public-Subnet-2"
  }
}

# Subnets Privadas
resource "aws_subnet" "Cloud9_private_subnet_1" {
  vpc_id                  = aws_vpc.Cloud9_vpc.id
  cidr_block              = "172.16.64.0/19"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "Cloud9-Private-Subnet-1"
  }
}

resource "aws_subnet" "Cloud9_private_subnet_2" {
  vpc_id                  = aws_vpc.Cloud9_vpc.id
  cidr_block              = "172.16.96.0/19"
  availability_zone       = "us-east-1c"
  map_public_ip_on_launch = false

  tags = {
    Name = "Cloud9-Private-Subnet-2"
  }
}

# Asociaciones de Route Tables a Subnets
resource "aws_route_table_association" "public_subnet_1_assoc" {
  subnet_id      = aws_subnet.Cloud9_public_subnet_1.id
  route_table_id = aws_route_table.Cloud9_public_rt.id
}

resource "aws_route_table_association" "public_subnet_2_assoc" {
  subnet_id      = aws_subnet.Cloud9_public_subnet_2.id
  route_table_id = aws_route_table.Cloud9_public_rt.id
}

resource "aws_route_table_association" "private_subnet_1_assoc" {
  subnet_id      = aws_subnet.Cloud9_private_subnet_1.id
  route_table_id = aws_route_table.Cloud9_private_rt_1.id
}

resource "aws_route_table_association" "private_subnet_2_assoc" {
  subnet_id      = aws_subnet.Cloud9_private_subnet_2.id
  route_table_id = aws_route_table.Cloud9_private_rt_2.id
}