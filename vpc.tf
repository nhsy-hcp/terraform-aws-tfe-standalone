module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~>5.0"

  name = "tfe-${random_pet.tfe.id}"

  cidr = var.vpc_cidr

  azs = slice(data.aws_availability_zones.available.names, 0, 3)

  public_subnet_tags = { "Subnet-Type" : "public" }

  public_subnets = [
    cidrsubnet(var.vpc_cidr, 8, 0),
    cidrsubnet(var.vpc_cidr, 8, 1),
    cidrsubnet(var.vpc_cidr, 8, 2)
  ]

  enable_nat_gateway   = false
  enable_dns_hostnames = true
}


