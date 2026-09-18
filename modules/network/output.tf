# output "az_name" {
#   value = var.az_names
# }
#   + az_names = [
#       + "ap-southeast-1a",
#       + "ap-southeast-1b",
#       + "ap-southeast-1c",
#     ]

# output "subnet_ids" {
#   value = { for k, s in aws_subnet.subnet : k => s.id }
# }
#   + subnet   = {
#       + Cluster1a = (known after apply)
#       + Cluster1b = (known after apply)
#       + Cluster1c = (known after apply)
#       + private1a = (known after apply)
#       + private1b = (known after apply)
#       + private1c = (known after apply)
#       + public1a  = (known after apply)
#       + public1b  = (known after apply)
#       + public1c  = (known after apply)
#     }

# output "private_rt_ids" {
#   value = { for k, s in aws_route_table.private_rt : k => s.id }
# }

#   + private_rt_ids = {
#       + ap-southeast-1a = (known after apply)
#       + ap-southeast-1b = (known after apply)
#       + ap-southeast-1c = (known after apply)
#     }

output "external_alb_sg_id" {
  value = aws_security_group.external_alb_sg.id
}

# modules/network/outputs.tf
output "subnet_ids_by_type" {
  value = {
    for t in distinct([for s in values(local.subnet_map) : s.type]) : t => [
      for k, s in local.subnet_map : aws_subnet.subnet[k].id if s.type == t
    ]
  }
}
