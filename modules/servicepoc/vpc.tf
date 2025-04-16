resource "aws_vpc" "vpc" {
  cidr_block = var.vpc.cidr

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc.name
  }
}

resource "aws_subnet" "subnets" {
  count = length(var.vpc.subnets)

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.vpc.subnets[count.index]
  availability_zone = var.vpc.azs[count.index]

  tags = {
    Name = "${var.name}-subnet-${count.index + 1}"
  }
}

resource "aws_route_table" "subnets_rts" {
  count  = length(aws_subnet.subnets)
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block       = "0.0.0.0/0"
    core_network_arn = var.core_network_arn
  }

  depends_on = [
    aws_networkmanager_attachment_accepter.vpc_attachment_accepter
  ]
}

resource "aws_route_table_association" "subnets_rts_ass" {
  count = length(aws_subnet.subnets)

  subnet_id      = aws_subnet.subnets[count.index].id
  route_table_id = aws_route_table.subnets_rts[count.index].id
}

resource "aws_networkmanager_vpc_attachment" "vpc_attachment" {
  core_network_id = var.core_network_id
  vpc_arn         = aws_vpc.vpc.arn
  subnet_arns     = [for subnet in aws_subnet.subnets : subnet.arn]

  tags = {
    Name     = "${var.name}-core-network-attachment"
    CWAttach = var.cw_attach
  }
}

resource "aws_networkmanager_attachment_accepter" "vpc_attachment_accepter" {
  attachment_id   = aws_networkmanager_vpc_attachment.vpc_attachment.id
  attachment_type = aws_networkmanager_vpc_attachment.vpc_attachment.attachment_type
}
