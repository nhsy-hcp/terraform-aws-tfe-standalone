output "ssm_connect" {
  value = "aws ssm start-session --region=${var.region} --target=${module.tfe.id}"
}