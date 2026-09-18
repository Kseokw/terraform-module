# 보안그룹 생성
# ===============================================================================================

# nat
resource "aws_security_group" "nat_sg" {
  name        = "${local.tag_header}-nat-sg"
  description = "22, 80, 443, all" # 설명 수정
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    # 218.235.89.82 현재공인 IP
    cidr_blocks = ["218.235.89.82/32"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    # 0.0.0.0/0 대신 현재 생성한 VPC의 CIDR 대역(10.0.0.0/16)만 허용
    cidr_blocks = [aws_vpc.vpc.cidr_block]
  }

  egress { # outbound 규칙
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # 모든 프로토콜 허용
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.tag_header}-nat-sg" # 태그 이름 수정
  }
}

# ssh
resource "aws_security_group" "internal_ssh_sg" {
  name        = "${local.tag_header}-internal-ssh-sg"
  description = "22/nat-sg" # 설명 수정
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.nat_sg.id]
  }

  egress { # outbound 규칙
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # 모든 프로토콜 허용
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.tag_header}-internal-ssh-sg" # 태그 이름 수정
  }
}

# external-alb
resource "aws_security_group" "external_alb_sg" {
  name        = "${local.tag_header}-external-alb-sg"
  description = "80, 443, 8000" # 설명 수정
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress { # outbound 규칙
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # 모든 프로토콜 허용
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.tag_header}-external-alb-sg" # 태그 이름 수정
  }
}

# internal-alb
resource "aws_security_group" "internal_alb_sg" {
  name        = "${local.tag_header}-internal-alb-sg"
  description = "80, 443, 8000"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.external_alb_sg.id]
  }
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.external_alb_sg.id]
  }
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc.cidr_block]
  }

  egress { # outbound 규칙
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.tag_header}-internal-alb-sg"
  }
}

# database
resource "aws_security_group" "internal_mysql_maria_sg" {
  name        = "${local.tag_header}-internal-mysql-maria-sg"
  description = "mysql_maria_3306"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc.cidr_block]
  }

  egress { # outbound 규칙
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.tag_header}-internal-mysql-maria-sg"
  }
}

resource "aws_security_group" "internal_postgresql_sg" {
  name        = "${local.tag_header}-internal-postgresql-sg"
  description = "postgresql_5432"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.tag_header}-internal-postgresql-sg"
  }
}

resource "aws_security_group" "internal_oracle_sg" {
  name        = "${local.tag_header}-internal-oracle-sg"
  description = "oracle_1521"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.tag_header}-internal-oracle-sg"
  }
}

resource "aws_security_group" "internal_mssql_sg" {
  name        = "${local.tag_header}-internal-mssql-sg"
  description = "mssql_1433"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 1433
    to_port     = 1433
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.tag_header}-internal-mssql-sg"
  }
}

resource "aws_security_group" "internal_redis_sg" {
  name        = "${local.tag_header}-internal-redis-sg"
  description = "redis_6379"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.tag_header}-internal-redis-sg"
  }
}

# eks
resource "aws_security_group" "cluster_sg" {
  name        = "${local.tag_header}-cluster-sg"
  description = "EKS control plane"
  vpc_id      = aws_vpc.vpc.id
  tags        = { Name = "${local.tag_header}-cluster-sg" }
}

resource "aws_security_group" "eks_node_sg" {
  name        = "${local.tag_header}-eks-node-sg"
  description = "EKS worker nodes"
  vpc_id      = aws_vpc.vpc.id
  tags        = { Name = "${local.tag_header}-eks-node-sg" }
}

# cluster_sg 인바운드
resource "aws_vpc_security_group_ingress_rule" "cluster_from_node" {
  security_group_id            = aws_security_group.cluster_sg.id
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  referenced_security_group_id = aws_security_group.eks_node_sg.id
}

resource "aws_vpc_security_group_ingress_rule" "cluster_from_office" {
  security_group_id = aws_security_group.cluster_sg.id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

# eks_node_sg 인바운드
resource "aws_vpc_security_group_ingress_rule" "node_from_alb_80" {
  security_group_id            = aws_security_group.eks_node_sg.id
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
  referenced_security_group_id = aws_security_group.external_alb_sg.id
}

resource "aws_vpc_security_group_ingress_rule" "node_from_alb_443" {
  security_group_id            = aws_security_group.eks_node_sg.id
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  referenced_security_group_id = aws_security_group.external_alb_sg.id
}

resource "aws_vpc_security_group_ingress_rule" "node_kubelet" {
  security_group_id            = aws_security_group.eks_node_sg.id
  ip_protocol                  = "tcp"
  from_port                    = 10250
  to_port                      = 10250
  referenced_security_group_id = aws_security_group.cluster_sg.id
}

# 노드 간 전체 통신 (self)
resource "aws_vpc_security_group_ingress_rule" "node_self" {
  security_group_id            = aws_security_group.eks_node_sg.id
  ip_protocol                  = "-1"
  referenced_security_group_id = aws_security_group.eks_node_sg.id
}

# 아웃바운드 전체 허용 (SG마다 1개씩 필요)
resource "aws_vpc_security_group_egress_rule" "cluster_all" {
  security_group_id = aws_security_group.cluster_sg.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "node_all" {
  security_group_id = aws_security_group.eks_node_sg.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# 순환참조로 인한 오류 발생 예상으로 주석처리
# # EKS
# resource "aws_security_group" "cluster_sg" {
#   name        = "${local.tag_header}-cluster-sg"
#   description = "443"
#   vpc_id      = aws_vpc.vpc.id

#   ingress {
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   ingress {
#     from_port       = 443
#     to_port         = 443
#     protocol        = "tcp"
#     security_groups = [aws_security_group.eks_node_sg]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "${local.tag_header}-cluster-sg"
#   }
# }

# # EKS Node
# resource "aws_security_group" "eks_node_sg" {
#   name        = "${local.tag_header}-eks-node-sg"
#   description = "80, 443, 10250"
#   vpc_id      = aws_vpc.vpc.id

#   ingress {
#     from_port       = 80
#     to_port         = 80
#     protocol        = "tcp"
#     security_groups = [aws_security_group.external_alb_sg]
#   }
#   ingress {
#     from_port       = 443
#     to_port         = 443
#     protocol        = "tcp"
#     security_groups = [aws_security_group.external_alb_sg]
#   }
#   ingress {
#     from_port       = 10250
#     to_port         = 10250
#     protocol        = "tcp"
#     security_groups = [aws_security_group.cluster_sg]
#   }
#   ingress {
#     from_port = all
#     to_port   = all
#     protocol  = "-1"
#     self      = true
#   }
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "${local.tag_header}-eks-node-sg"
#   }
# }
