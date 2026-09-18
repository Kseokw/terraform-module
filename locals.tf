# 모듈에서 메인으로 넘기고 다른 모듈로 넘겨주어야 함
# 모듈에서 output으로 넘겨주어야 가능함

# <변수명> = <모듈명.아웃풋이름>

locals {
  # ["ap-southeast-1", ... ]
  az_names    = data.aws_availability_zones.available_az.names
  vpc_cidr    = var.vpc_cidr
  tag_header  = var.tag_header
  cidr_header = "${split(".", var.vpc_cidr)[0]}.${split(".", var.vpc_cidr)[1]}"
  subnet_map = merge([
    # idx = subnet 3옥텟 구분
    # key = type 구분
    for idx, key in var.subnet_type : {
      for i, az_name in local.az_names : "${key}${split("-", az_name)[2]}" => {
        type = key
        az   = az_name
        cidr = "${local.cidr_header}.${(idx * 10) + (i + 1)}.0/24"
      }
    }
  ]...)
  subnet_type     = var.subnet_type
  region          = "ap-southeast-1"
  instance_subnet = "public1a"
}

