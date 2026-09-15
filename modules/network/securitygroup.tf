# # 보안그룹 생성
# resource "aws_security_group" "NAT_sg" {
#   name        = "${local.tag_header}-NAT-sg"
#   description = "NAT"
#   vpc_id      = aws_vpc.vpc.id

#   dynamic "ingress" {
#     for_each = [22, 80, 443]
#     content { # inbound 규칙
#       from_port   = ingress.value
#       to_port     = ingress.value
#       protocol    = "tcp"
#       cidr_blocks = ["0.0.0.0/0"]
#     }
#   }

#   egress { # outbound 규칙
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1" # 모든 프로토콜 허용
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "NAT-sg"
#   }
# }

# resource "aws_security_group" "SSH_sg" {
#   name        = "${local.tag_header}-SSH-sg"
#   description = "SSH"
#   vpc_id      = aws_vpc.vpc.id

#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = [aws_security_group.NAT_sg]
#   }


#   egress { # outbound 규칙
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1" # 모든 프로토콜 허용
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "NAT-sg"
#   }
# }
# resource "aws_security_group" "std07_lab_mysql_sg" {
#   name        = "std07-lab-mysql-sg"
#   description = "Allow MySQL inbound traffic from VPC" # 설명 수정
#   vpc_id      = aws_vpc.std07_lab_vpc.id

#   # MySQL 전용 3306 포트 오픈 및 내부 네트워크(VPC)에서만 접근 허용
#   ingress {
#     from_port = 3306
#     to_port   = 3306
#     protocol  = "tcp"
#     # 0.0.0.0/0 대신 현재 생성한 VPC의 CIDR 대역(10.0.0.0/16)만 허용
#     cidr_blocks = [aws_vpc.std07_lab_vpc.cidr_block]
#   }

#   egress { # outbound 규칙
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1" # 모든 프로토콜 허용
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "std07-lab-mysql-sg" # 태그 이름 수정
#   }
# }

# # NACL
# # 서브넷 전용 방화벽
# # - 서브넷 단위로 규칙 적용
# # - 규칙 번호 기반 순위 평가: 100번에서 막고 200번에서 열어주면 결론은 막힘
# # - 상태를 기억하지 않음: inbound 를 허용해도 outbound 규칙이 없으면 못나감
# resource "aws_network_acl" "std07_lab_nacl" {
#   vpc_id = aws_vpc.std07_lab_vpc.id
#   ingress {
#     rule_no    = 103 # rule_no는 중복되지 않게 작성
#     protocol   = "tcp"
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 22
#     to_port    = 22
#   }
#   ingress {
#     rule_no    = 100 # rule_no는 중복되지 않게 작성
#     protocol   = "tcp"
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 80
#     to_port    = 80
#   }
#   ingress {
#     rule_no    = 101 # rule_no는 중복되지 않게 작성
#     protocol   = "tcp"
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 443
#     to_port    = 443
#   }
#   # [추가] 돌아오는 응답을 받기 위한 임시 포트 허용
#   ingress {
#     rule_no    = 102
#     protocol   = "tcp"
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 1024
#     to_port    = 65535
#   }
#   # ICMP (Ping 등) 허용 규칙
#   ingress {
#     rule_no    = 104
#     protocol   = "icmp"
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 0
#     to_port    = 0
#     # 포트 대신 ICMP 타입과 코드 지정 (전체 허용은 -1)
#     icmp_type = -1
#     icmp_code = -1
#   }
#   egress {
#     rule_no    = 100 # rule_no는 중복되지 않게 작성(ingress, egress 규칙번호 중첩 가능, 따로 적용됨)
#     protocol   = "-1"
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 0
#     to_port    = 0
#   }
#   tags = {
#     Name = "std07-lab-nacl"
#   }
# }

# # NACL - subnet 연결
# resource "aws_network_acl_association" "std07_lab_nacl_1a_assoc" {
#   subnet_id      = aws_subnet.std07_lab_public_1a_subnet.id
#   network_acl_id = aws_network_acl.std07_lab_nacl.id
# }

# # NACL - 1b 서브넷 연결 추가
# resource "aws_network_acl_association" "std07_lab_nacl_1b_assoc" {
#   subnet_id      = aws_subnet.std07_lab_public_1b_subnet.id
#   network_acl_id = aws_network_acl.std07_lab_nacl.id
# }

# # NACL - 1b 서브넷 연결 추가
# resource "aws_network_acl_association" "std07_lab_nacl_1c_assoc" {
#   subnet_id      = aws_subnet.std07_lab_public_1c_subnet.id
#   network_acl_id = aws_network_acl.std07_lab_nacl.id
# }
