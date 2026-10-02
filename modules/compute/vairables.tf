variable "tag_header" {
  description = "tag_header"
  type        = string
  default     = ""
}

variable "instance_subnet" {
  description = "instance_subnet"
  type        = string
  default     = ""
}

variable "subnet_ids" {
  type = map(string)
}

variable "security_group_ids" {
  type = list(string)
}
