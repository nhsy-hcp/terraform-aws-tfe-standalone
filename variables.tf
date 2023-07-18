variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.64.0.0/16"
}

variable "aws_account_id" {
  type = string
}

variable "owner" {
  type    = string
  default = "nhsy"
}
