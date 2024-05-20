resource "aws_vpc" "vpc" {
  cidr_block          = var.cidr

  tags = merge(
    { "Name" = var.name },
    var.tags
  )
}

################################################################################
# Publiс Subnets
################################################################################
resource "aws_subnet" "public" {
  count = length(var.public_subnets)

  availability_zone                              = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) > 0 ? element(var.azs, count.index) : null
  availability_zone_id                           = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) == 0 ? element(var.azs, count.index) : null
  cidr_block                                     = element(concat(var.public_subnets, [""]), count.index)

  #   We don't actually want to launch things in the public subnet unless they are ALBs etc.
  map_public_ip_on_launch                        = false
  vpc_id                                         = aws_vpc.vpc.id 

  tags = merge(
    {
      Name = try(
        format("${var.name}-public-%s", element(var.azs, count.index))
      )
    },
    var.tags,
  )
}

locals {
  num_public_route_tables = length(var.azs)
}

resource "aws_route_table" "public" {
  count = local.num_public_route_tables

  vpc_id = aws_vpc.vpc.id

  tags = merge(
    {
      "Name" = format(
        "${var.name}-public-%s",
        element(var.azs, count.index),
      )
    },
    var.tags,
  )
}

resource "aws_route_table_association" "public" {
  count = length(var.azs) 

  subnet_id      = element(aws_subnet.public[*].id, count.index)
  route_table_id = element(aws_route_table.public[*].id, count.index)
}

resource "aws_route" "public_internet_gateway" {
  count = length(var.azs) 

  route_table_id         = element(aws_route_table.public[*].id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id

  timeouts {
    create = "5m"
  }
}

################################################################################
# Private Subnets
################################################################################
resource "aws_subnet" "private" {
  count = length(var.azs)

  availability_zone                              = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) > 0 ? element(var.azs, count.index) : null
  availability_zone_id                           = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) == 0 ? element(var.azs, count.index) : null
  cidr_block                                     = element(concat(var.private_subnets, [""]), count.index)

  vpc_id                                         = aws_vpc.vpc.id 

  tags = merge(
    {
      Name = try(
        format("${var.name}-private-%s", element(var.azs, count.index))
      )
    },
    var.tags,
  )
}

# There are as many routing tables as the number of NAT gateways
resource "aws_route_table" "private" {
  count = length(var.azs) 

  vpc_id = aws_vpc.vpc.id 

  tags = merge(
    {
      "Name" = format(
        "${var.name}-private-%s",
        element(var.azs, count.index),
      )
    },
    var.tags,
  )
}

resource "aws_route_table_association" "private" {
  count = length(var.azs) 

  subnet_id = element(aws_subnet.private[*].id, count.index)
  route_table_id = element(
    aws_route_table.private[*].id,
    count.index,
  )
}

################################################################################
# Internet Gateway
################################################################################
resource "aws_internet_gateway" "this" {
  count = 1 

  vpc_id = aws_vpc.vpc.id 

  tags = merge(
    { "Name" = var.name },
    var.tags,
  )
}

################################################################################
# NAT Gateway
################################################################################
resource "aws_eip" "nat" {
  count = length(var.azs) 

  domain = "vpc"

  tags = merge(
    {
      "Name" = format(
        "${var.name}-%s",
        element(var.azs, count.index),
      )
    },
    var.tags,
  )

  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this" {
  count = length(var.azs) 

  allocation_id = element(
    aws_eip.nat[*].id,
    count.index
  )

  subnet_id = element(
    aws_subnet.public[*].id,
    count.index,
  )

  tags = merge(
    {
      "Name" = format(
        "${var.name}-%s",
        element(var.azs, count.index),
      )
    },
    var.tags,
  )

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route" "private_nat_gateway" {
  count = length(var.azs) 

  route_table_id         = element(aws_route_table.private[*].id, count.index)
  destination_cidr_block = var.nat_gateway_destination_cidr_block
  nat_gateway_id         = element(aws_nat_gateway.this[*].id, count.index)

  timeouts {
    create = "5m"
  }
}
