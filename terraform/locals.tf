locals {
  ami_id      = "ami-040f117aa9030c487"
  application = "webapp"
  common_tags = {
    application = local.application
  }
}
