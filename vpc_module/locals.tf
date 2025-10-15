locals {
    common_tags = {
        project = var.project
        env = var.env
        terraform = true
    }
}
locals {
  az = slice(data.aws_availability_zones.available.names,0,2)
}