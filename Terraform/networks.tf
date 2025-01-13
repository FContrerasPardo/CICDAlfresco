resource "aws_vpc" "alfresco_vpc" {
  cidr_block           = "192.168.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "alfresco VPC"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.alfresco_vpc.id
  tags = {
    Name = "Gateway"
  }
}

resource "aws_route_table" "alfresco_table" {
  vpc_id = aws_vpc.alfresco_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_subnet" "alfresco_subnet_one" {
  vpc_id            = aws_vpc.alfresco_vpc.id
  cidr_block        = "192.168.10.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  depends_on = [aws_internet_gateway.gw]
}

resource "aws_route_table_association" "subnet_one_public" {
  subnet_id      = aws_subnet.alfresco_subnet_one.id
  route_table_id = aws_route_table.alfresco_table.id
}

resource "aws_subnet" "alfresco_subnet_two" {
  vpc_id            = aws_vpc.alfresco_vpc.id
  cidr_block        = "192.168.20.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true
  depends_on = [aws_internet_gateway.gw]
}

resource "aws_route_table_association" "subnet_two_public" {
  subnet_id      = aws_subnet.alfresco_subnet_two.id
  route_table_id = aws_route_table.alfresco_table.id
}
