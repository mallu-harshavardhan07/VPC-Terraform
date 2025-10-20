resource "aws_vpc" "main" {
  cidr_block       = var.vpc_cidr_block
  instance_tenancy = "default"
  enable_dns_hostnames = true

  tags = local.common_tags
}
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags,
  {
    Name = "main"
  }
  )
}

resource "aws_subnet" "public_subnet" {
  count = length(var.public_cidr_subnet)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_cidr_subnet[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]


}
resource "aws_subnet" "private_subnet" {
  count = length(var.private_cidr_subnet)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_cidr_subnet[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

}
resource "aws_subnet" "database_subnet" {
  count = length(var.database_cidr_subnet)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.database_cidr_subnet[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

}
resource "aws_eip" "lb" {
  //instance = aws_instance.web.id
  domain   = "vpc"
}
resource "aws_nat_gateway" "example" {
  allocation_id = aws_eip.lb.id
  subnet_id     = aws_subnet.public_subnet[0].id

  tags = {
    Name = "gw NAT"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.gw]
}
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
}
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id
}
resource "aws_route_table" "database_rt" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "public_r" {
  route_table_id            = aws_route_table.public_rt.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.gw.id
}
resource "aws_route" "private_r" {
  route_table_id            = aws_route_table.private_rt.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_eip.lb.id
}
resource "aws_route" "database_r" {
  route_table_id            = aws_route_table.database_rt.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_eip.lb.id
}

resource "aws_route_table_association" "public_rta" {
  count = length(var.public_cidr_subnet)
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_rt.id
}
resource "aws_route_table_association" "private_rta" {
  count = length(var.private_cidr_subnet)
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_rt.id
}
resource "aws_route_table_association" "database_rta" {
  count = length(var.database_cidr_subnet)
  subnet_id      = aws_subnet.database_subnet[count.index].id
  route_table_id = aws_route_table.database_rt.id
}



resource "aws_vpc_peering_connection" "foo" {
  count = var.is_peering_required ? 1 : 0
  //peer_owner_id = var.peer_owner_id
  peer_vpc_id   = data.aws_vpc.default.id
  vpc_id        = aws_vpc.main.id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  requester {
    allow_remote_vpc_dns_resolution = true
  }
  auto_accept = true

}
resource "aws_route" "public_peer" {
  count = var.is_peering_required ? 1 : 0
  route_table_id            = aws_route_table.public_rt.id
  destination_cidr_block    = data.aws_vpc.default.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.foo[0].id
}
resource "aws_route" "default_route" {
  count = var.is_peering_required ? 1 : 0
  route_table_id            = data.aws_vpc.default.main_route_table_id
  destination_cidr_block    = var.vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.foo[0].id
}