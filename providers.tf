provider "aws" {
  region              = var.region
  allowed_account_ids = [var.aws_account_id] #check correct AWS account

  default_tags {
    tags = {
      owner : var.owner
    }
  }
}
