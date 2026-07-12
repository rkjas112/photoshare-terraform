data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  public_subnets  = zipmap(local.azs, var.public_subnet_cidrs)
  private_subnets = zipmap(local.azs, var.private_subnet_cidrs)
}

resource "aws_vpc" "photoshare" {
  cidr_block = var.vpc_cidr

  tags = { Name = "${var.project_name}-vpc" }
}

resource "aws_subnet" "public" {
  for_each = local.public_subnets

  vpc_id                  = aws_vpc.photoshare.id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = true

  tags = { Name = "${var.project_name}-public-${each.key}" }
}

resource "aws_subnet" "private" {
  for_each = local.private_subnets

  vpc_id            = aws_vpc.photoshare.id
  cidr_block        = each.value
  availability_zone = each.key

  tags = { Name = "${var.project_name}-private-${each.key}" }
}




resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.photoshare.id
  tags = { Name = "photoshare-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.photoshare.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "${var.project_name}-public-rt"
  }
}


resource "aws_route_table" "private" {
  vpc_id = aws_vpc.photoshare.id
  tags = { Name = "${var.project_name}-private-rt"
  }

}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

# --- moved blocks: rename existing state addresses, no destroy/create ---
moved {
  from = aws_subnet.public_1
  to   = aws_subnet.public["ap-south-1a"]
}

moved {
  from = aws_subnet.public_2
  to   = aws_subnet.public["ap-south-1b"]
}

moved {
  from = aws_route_table_association.public_1
  to   = aws_route_table_association.public["ap-south-1a"]
}

moved {
  from = aws_route_table_association.public_2
  to   = aws_route_table_association.public["ap-south-1b"]
}

moved {
  from = aws_subnet.private_1
  to   = aws_subnet.private["ap-south-1a"]
}

moved {
  from = aws_subnet.private_2
  to   = aws_subnet.private["ap-south-1b"]
}





