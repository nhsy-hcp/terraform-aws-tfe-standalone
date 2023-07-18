module "sg_remote_mgmt_allow_all" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = "remote-mgmt-allow-all"
  description = "Security group for EC2 instance"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = [local.management_cidr]
  ingress_rules       = ["all-all"]
  egress_rules        = ["all-all"]
}
