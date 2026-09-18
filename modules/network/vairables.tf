variable "vpc_cidr" {
  description = "vpc_cidr"
  type        = string
  default     = ""

}

variable "tag_header" {
  description = "tag_header"
  type        = string
  default     = ""

}

variable "az_names" {
  description = "가용영역 이름"
  type        = list(string)
  default     = []

}

variable "subnet_map" {
  description = "서브넷 생성 맵"
  type = map(object({
    az   = string
    cidr = string
    type = string
  }))
}

variable "subnet_type" {
  description = "서브넷 역할"
  type        = list(string)
  default     = []
}

variable "region" {
  description = "region"
  type        = string
  default     = ""
}

variable "instance_subnet" {
  description = "instance_subnet"
  type        = string
  default     = ""
}

