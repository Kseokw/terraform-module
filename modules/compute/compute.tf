# resource "aws_instance" "instance" {
#   # ami
#   ami = "ami-03acbba64aef9bf5c" # ubuntu 24.04
#   # instance type
#   instance_type = "t3.nano"
#   # key pair, key_name
#   key_name = "std07-key"
#   # volume
#   root_block_device {
#     volume_size           = 8     # 단위 GB
#     volume_type           = "gp3" # 볼륨 타입(최신 가성비 타입인 gp3 권장)
#     delete_on_termination = true  # 인스턴스 삭제 시 볼륨도 함께 삭제(안정성을 고려하면 Flase 부여)
#     tags = {
#       Name = "${local.tag_header}-instance-volume"
#     }
#   }
#   ebs_block_device {
#     device_name           = "${local.tag_header}-instance-add-volume"
#     volume_size           = 5
#     volume_type           = "gp3"
#     delete_on_termination = true
#     tags = {
#       Name = "${local.tag_header}-instance-add-volume"
#     }
#   }

#   # subnet
#   subnet_id = aws_subnet.subnet[local.instance_subnet].id
#   # 보안그룹
#   vpc_security_group_ids = [
#     # aws_security_group.ssh_sg.id,
#     # aws_security_group.internal_alb_sg
#     aws_security_group.nat_sg.id
#   ]
#   # User Data
#   user_data = <<-EOF
#     #!/bin/bash
#     #!/bin/bash
#     set -e
#     apt update -y
#     apt install -y curl unzip

#     curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
#     sh /tmp/get-docker.sh
#     systemctl enable --now docker
#     usermod -aG docker ubuntu

#     # # EFS 마운트
#     # mkdir -p /mnt/efs
#     # echo "${local.efs_id}.efs.${local.region}.amazonaws.com:/ /mnt/efs nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,_netdev 0 0" >> /etc/fstab
#     # mount -a
#     EOF

#   tags = {
#     Name = "${local.tag_header}-instance"
#   }
# }
