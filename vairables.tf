variable "tag_header" {
  description = "사용자 계정 명"
  type        = string
  default     = "std07"
}


variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_type" {
  description = "생성할 서브넷의 종류(망 구분) 리스트입니다. 순서대로 0번대, 10번대, 20번대... IP 대역이 할당됩니다."
  type        = list(string)
  default     = ["public", "private", "Cluster"]
}
