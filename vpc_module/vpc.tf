# This is used for creating vpc with the paramenters passed in module
resource "aws_vpc" "main" {
  cidr_block       =  var.vpc_cidr_block
  instance_tenancy = "default"
  enable_dns_hostnames = true

  tags = merge(local.common_tags,
   {
    Name = "${var.project}-${var.env}-vpc"
  }
  )
}
# creating Internet Gateway and connecting to vpc
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  
  tags = merge(
    local.common_tags,
    {
      Name = "${var.project}-${var.env}-Gateway"
    }
  )
}
# As our project requires 3 subnets (public,private,database) we are creating 3 subnets
resource "aws_subnet" "public_subnet" {
  count = length(var.public_cidr_subnet)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_cidr_subnet[count.index]
  availability_zone = local.az[count.index]

  tags = merge(local.common_tags,
    {
      Name = "${var.project}-${var.env}-public-${local.az[count.index]}"
    }
  )
}

resource "aws_subnet" "private_subnet" {
  count = length(var.private_cidr_subnet)
  vpc_id = aws_vpc.main.id
  cidr_block = var.private_cidr_subnet[count.index]
  availability_zone = local.az[count.index]
  tags = merge(local.common_tags,
    {
      Name = "${var.project}-${var.env}-private-${local.az[count.index]}"
    }
  )
  
}
resource "aws_subnet" "database_subnet" {
  count = length(var.database_cidr_subnet)
  vpc_id = aws_vpc.main.id
  cidr_block = var.database_cidr_subnet[count.index]
  availability_zone = local.az[count.index]
  tags = merge(local.common_tags,
    {
      Name = "${var.project}-${var.env}-database-${local.az[count.index]}"
    }
  )
  

}
# Creating an elastic ip resource
resource "aws_eip" "lb" {
 // instance = aws_instance.web.id
  domain   = "vpc"
}
# Creating an Nat-gateway in public subnet 
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.lb.id
  subnet_id     = aws_subnet.public_subnet[0].id

 tags = merge(local.common_tags,
    {
      Name = "${var.project}-${var.env}-NAT-gateway"
    }
  )

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.gw]
}
# creating 3 AWS_Route_Table for the 3 subnets
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project}-${var.env}-public_route_table"
  }
}
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project}-${var.env}-private_route_table"
  }
}
resource "aws_route_table" "database_route_table" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project}-${var.env}-database_route_table"
  }
}
#we are providing a resource to create routing table entry in vpc routing table
resource "aws_route" "public_route" {
  route_table_id            = aws_route_table.public_route_table.id
  destination_cidr_block    = "0.0.0.0/16"
  gateway_id = aws_internet_gateway.gw.id
  
}

resource "aws_route" "private_route" {
  route_table_id            = aws_route_table.private_route_table.id
  destination_cidr_block    = "0.0.0.0/16"
  nat_gateway_id = aws_nat_gateway.main.id
}

resource "aws_route" "database_route" {
  route_table_id            = aws_route_table.database_route_table.id
  destination_cidr_block    = "0.0.0.0/16"
  nat_gateway_id = aws_nat_gateway.main.id
}
# We are connecting routetables to the respective subnets 
resource "aws_route_table_association" "public_rta" {
  count = length(var.public_cidr_subnet)
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}
resource "aws_route_table_association" "private_rta" {
  count = length(var.private_cidr_subnet)
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_route_table.id
}
resource "aws_route_table_association" "database_rta" {
  count = length(var.database_cidr_subnet)
  subnet_id      = aws_subnet.database_subnet[count.index].id
  route_table_id = aws_route_table.database_route_table.id
}
//The below logic i used in data.tf to fetch information 
/*
data "aws_vpc" "default" {
    default = true
  
}
data "aws_route_table" "main"{
    vpc_id = data.aws_vpc.default.id
    filter {
    name   = "association.main"
    values = ["true"]
  }
} */

resource "aws_vpc_peering_connection" "foo" {
  //peer_owner_id = var.peer_owner_id
  count = var.is_peering_required ? 1 : 0
  peer_vpc_id   = data.aws_vpc.default.id
  vpc_id        = aws_vpc.main.id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  requester {
    allow_remote_vpc_dns_resolution = true
  }
  //Automatically accepts the peering request if both VPCs belong to the same AWS account.
  //Saves you from manually logging into the console to accept it.
  auto_accept = true
}


resource "aws_route" "public_peering" {
  count = var.is_peering_required ? 1 : 0
  route_table_id            = aws_route_table.public_route_table.id
  destination_cidr_block    = data.aws_vpc.default.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.foo[count.index].id
}

resource "aws_route" "default_peering" {
  count = var.is_peering_required ? 1 : 0
  route_table_id            = data.aws_route_table.main.id
  destination_cidr_block    = var.vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.foo[count.index].id
}
