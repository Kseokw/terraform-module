# 사용할 모듈블럭 정의
module "network" {
  source = "./modules/network"
  # 다른 리전을 사용하고자 할 경우, provider {}에 미리 정의 되어있어야 함.
  # providers = {
  #   aws = aws.seoul
  # }

  # <모듈 변수명> = <모듈로 넘겨줄 값 | var.변수명 | local.변수명>
  az_names    = local.az_names
  vpc_cidr    = local.vpc_cidr
  tag_header  = local.tag_header
  subnet_map  = local.subnet_map
  subnet_type = local.subnet_type
}









# 모듈의 output을 메인에서 가져다 쓸 수 있다.
# output "vpc_id" {
#   value = module.network.vpc_id
# }
