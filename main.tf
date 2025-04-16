# inspection
module "inspection" {
  source = "./modules/inspection"

  name = "inspection"
  vpc = {
    name             = "inspection-vpc"
    cidr             = "10.0.0.0/24"
    interco_subnets  = ["10.0.0.0/28", "10.0.0.16/28"]
    firewall_subnets = ["10.0.0.32/28", "10.0.0.48/28"]
    azs              = ["eu-west-3a", "eu-west-3b"]
  }

  core_network_id  = aws_networkmanager_core_network.core_network.id
  core_network_arn = aws_networkmanager_core_network.core_network.arn
  cw_attach        = "POCInspectionNFG"
}

# POC project A
module "projectA" {
  source = "./modules/servicepoc"

  name   = "projectA"
  region = "eu-west-3"
  vpc = {
    name    = "vpc-A"
    cidr    = "100.64.0.0/16"
    subnets = ["100.64.0.0/24", "100.64.1.0/24"]
    azs     = ["eu-west-3a", "eu-west-3b"]
  }

  core_network_id  = aws_networkmanager_core_network.core_network.id
  core_network_arn = aws_networkmanager_core_network.core_network.arn
  cw_attach        = "SegA"

  depends_on = [
    module.inspection
  ]
}

# POC project B
module "projectB" {
  source = "./modules/servicepoc"

  name   = "projectB"
  region = "eu-west-3"
  vpc = {
    name    = "vpc-B"
    cidr    = "100.65.0.0/16"
    subnets = ["100.65.0.0/24", "100.65.1.0/24"]
    azs     = ["eu-west-3a", "eu-west-3b"]
  }

  core_network_id  = aws_networkmanager_core_network.core_network.id
  core_network_arn = aws_networkmanager_core_network.core_network.arn
  cw_attach        = "SegB"

  depends_on = [
    module.inspection
  ]
}
