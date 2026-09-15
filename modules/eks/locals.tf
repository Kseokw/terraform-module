locals {
  vpc_cidr    = var.vpc_cidr
  tag_header  = var.tag_header
  tag_module  = "eks"
  subnet_map  = var.subnet_map
  subnet_type = var.subnet_type
}
