# output "az_names" {
#   value = module.network.az_name
# }


# output "subnet" {
#   value = module.network.subnet_ids
# }

# output "vpc_cidr" {
#   value = "${split(".", var.vpc_cidr)[0]}.${split(".", var.vpc_cidr)[1]}"
# }

# output "vpc_cidr2" {
#   value = join(".", slice(split(".", var.vpc_cidr), 0, 2))
# }

# output "ids" {
#   value = "public${split("-", local.az_names[0])[2]}"
# }
#   + ids      = "public1a"

# output "subnet_map" {
#   value = local.subnet_map
# }

# + subnet_map = {
#     + Cluster1a = {
#         + az   = "ap-southeast-1a"
#         + cidr = "10.0.21.0/24"
#         + type = "Cluster"
#       }
#     + Cluster1b = {
#         + az   = "ap-southeast-1b"
#         + cidr = "10.0.22.0/24"
#         + type = "Cluster"
#       }
#     + Cluster1c = {
#         + az   = "ap-southeast-1c"
#         + cidr = "10.0.23.0/24"
#         + type = "Cluster"
#       }
#     + private1a = {
#         + az   = "ap-southeast-1a"
#         + cidr = "10.0.11.0/24"
#         + type = "private"
#       }
#     + private1b = {
#         + az   = "ap-southeast-1b"
#         + cidr = "10.0.12.0/24"
#         + type = "private"
#       }
#     + private1c = {
#         + az   = "ap-southeast-1c"
#         + cidr = "10.0.13.0/24"
#         + type = "private"
#       }
#     + public1a  = {
#         + az   = "ap-southeast-1a"
#         + cidr = "10.0.1.0/24"
#         + type = "public"
#       }
#     + public1b  = {
#         + az   = "ap-southeast-1b"
#         + cidr = "10.0.2.0/24"
#         + type = "public"
#       }
#     + public1c  = {
#         + az   = "ap-southeast-1c"
#         + cidr = "10.0.3.0/24"
#         + type = "public"
#       }
#   }

# output "private_rt_ids" {
#   value = module.network.private_rt_ids
# }

# output "public_rt_ids" {
#   value = module.network.public_rt_ids
# }
