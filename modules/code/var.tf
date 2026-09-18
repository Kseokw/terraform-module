variable "tag_header" {
  description = "tag_header"
  type        = string
  default     = ""

}

variable "subnet_map" {
  description = "서브넷 생성 맵"
  type = map(object({
    az   = string
    cidr = string
    type = string
  }))
}

variable "external_alb_sg_id" {
  description = "external_alb_sg_id"
  type        = string
}

variable "subnet_ids" {
  description = "ASG 인스턴스를 배치할 서브넷 ID 목록"
  type        = list(string)
}
