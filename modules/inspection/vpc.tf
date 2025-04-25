# inspection vpc
resource "aws_vpc" "inspection_vpc" {
  cidr_block = var.vpc.cidr

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.vpc.name}-inspection-vpc"
  }
}

# interco subnets
resource "aws_subnet" "interco_subnets" {
  count = length(var.vpc.interco_subnets)

  vpc_id            = aws_vpc.inspection_vpc.id
  availability_zone = var.vpc.azs[count.index]
  cidr_block        = var.vpc.interco_subnets[count.index]

  tags = {
    Name = "${var.name}-fw-interco-subnet-${count.index + 1}"
  }
}

resource "aws_route_table" "interco_subnets_rt" {
  count = length(aws_subnet.interco_subnets)

  vpc_id = aws_vpc.inspection_vpc.id
  route {
    cidr_block      = "0.0.0.0/0"
    vpc_endpoint_id = lookup(local.fw_vpc_endpoints, aws_subnet.firewall_subnets[count.index].id, null)

    # WORKS: if routing everything to a single firewall vpc endpoint
    #vpc_endpoint_id = lookup(local.fw_vpc_endpoints, aws_subnet.firewall_subnets[1].id, null)
  }

  tags = {
    Name = "${var.name}-interco-subnet-rt-${count.index + 1}"
  }
}

resource "aws_route_table_association" "interco_subnets_rt_association" {
  count = length(aws_subnet.interco_subnets)

  subnet_id      = aws_subnet.interco_subnets[count.index].id
  route_table_id = aws_route_table.interco_subnets_rt[count.index].id
}

# firewall subnets
resource "aws_subnet" "firewall_subnets" {
  count = length(var.vpc.firewall_subnets)

  vpc_id            = aws_vpc.inspection_vpc.id
  availability_zone = var.vpc.azs[count.index]
  cidr_block        = var.vpc.firewall_subnets[count.index]

  tags = {
    Name = "${var.name}-fw-subnet-${count.index + 1}"
  }
}

resource "aws_route_table" "firewall_subnets_rt" {
  count = length(aws_subnet.firewall_subnets)

  vpc_id = aws_vpc.inspection_vpc.id
  route {
    cidr_block       = "0.0.0.0/0"
    core_network_arn = var.core_network_arn
  }

  tags = {
    Name = "${var.name}-fw-subnet-rt-${count.index + 1}"
  }

  depends_on = [
    aws_networkmanager_attachment_accepter.vpc_attachment_accepter
  ]
}

resource "aws_route_table_association" "firewall_subnets_rt_association" {
  count = length(aws_subnet.firewall_subnets)

  subnet_id      = aws_subnet.firewall_subnets[count.index].id
  route_table_id = aws_route_table.firewall_subnets_rt[count.index].id
}

resource "aws_networkmanager_vpc_attachment" "vpc_attachment" {
  core_network_id = var.core_network_id
  vpc_arn         = aws_vpc.inspection_vpc.arn
  subnet_arns     = [for subnet in aws_subnet.interco_subnets : subnet.arn]

  options {
    appliance_mode_support = true
  }

  tags = {
    Name     = "${var.name}-core-network-attachment"
    CWAttach = var.cw_attach
  }
}

resource "aws_networkmanager_attachment_accepter" "vpc_attachment_accepter" {
  attachment_id   = aws_networkmanager_vpc_attachment.vpc_attachment.id
  attachment_type = aws_networkmanager_vpc_attachment.vpc_attachment.attachment_type
}
