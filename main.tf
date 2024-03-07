locals {
  inbound_ports = [22,443,80]
}

resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "eks-terraform"
  }
}

resource "aws_subnet" "public_subnets" {
  for_each = var.public_subnet
  vpc_id = aws_vpc.main.id
  cidr_block = each.value["cidr_block"]
  availability_zone = each.value["az"]
  map_public_ip_on_launch = true
  tags = {   
      Name = "eks-terraform-public-${each.key}"  
    }
}

resource "aws_subnet" "private_subnets" {
    for_each = var.private_subnets
    vpc_id = aws_vpc.main.id
    cidr_block = each.value["cidr_block"]
    availability_zone = each.value["az"]
    tags = {   
      Name = "eks-terraform-private-${each.key}"  
    }
  
}
resource "aws_internet_gateway" "main-igw" {
    vpc_id = aws_vpc.main.id

    tags = {   
      Name = "eks-terraform"  
    }
  
}

resource "aws_eip" "nat_eip" {
    for_each = aws_subnet.public_subnets
    depends_on = [ aws_route_table_association.public_subnets-rt-association ]
    domain = "vpc"
  
}

resource "aws_nat_gateway" "nat_gateway" {
    for_each = aws_subnet.public_subnets
    allocation_id = aws_eip.nat_eip[each.key].id
    subnet_id = aws_subnet.public_subnets[each.key].id
}

resource "aws_route_table" "route_table_private" {
    for_each = aws_subnet.public_subnets
    vpc_id = aws_vpc.main.id
    route  {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_nat_gateway.nat_gateway["${each.key}"].id
  
}
}

resource "aws_route_table_association" "rt_private_subnet_association" {
    for_each = aws_subnet.private_subnets
    route_table_id = aws_route_table.route_table_private[each.key].id
    subnet_id = aws_subnet.private_subnets[each.key].id
  
}
resource "aws_route_table" "route_table_public" {
    vpc_id = aws_vpc.main.id
    
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.main-igw.id
    }

    tags = {   
      Name = "eks-terraform"  
    }  
}

resource "aws_route_table_association" "public_subnets-rt-association" {
    for_each = var.public_subnet
    route_table_id = aws_route_table.route_table_public.id
    subnet_id = aws_subnet.public_subnets["${each.key}"].id
   
}

