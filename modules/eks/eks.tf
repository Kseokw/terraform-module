# EKS 구축 프로세스
# 네트워크 구성 => IAM권한설정 => EKS 클러스터 구성 => 노드 그룹 정의 => 액세스 환경 정의
# ===============================================================================
# 서브넷 공통: "kubernetes.io/cluster/<EKS이름" = "shared"
# 퍼블릭 서브넷: "kubernetes.io/role/elb" = "1"
# 프라이빗 서브넷: "kubernetes.io/role/internal-elb" = "1"

# ===============================================================================
# EKS 및 워커노드를 위한보안 그룹 생성
# 노드와 컨트롤 플레인(k8s master)간 통신을 위한 포트: 10250
# 노드간 통신 모두 열어줌? 뭔 말임?

resource "aws_security_group" "eks_sg" {
  name        = "${local.tag_header}-eks-sg"
  description = "Allow EKS VPC" # 설명 수정
  vpc_id      = aws_vpc.vpc.id

  # 노드와 컨트롤 플레인(k8s master)간 통신을 위한 포트: 10250
  # 노드간 통신 모두 열어줌? 뭔 말임?
  ingress {
    from_port = 10250
    to_port   = 10250
    protocol  = "tcp"
    # 0.0.0.0/0 대신 현재 생성한 VPC의 CIDR 대역(10.0.0.0/16)만 허용
    cidr_blocks = [aws_vpc.vpc.cidr_block]
  }

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
    # 출발지가 이 보안그룹 자신인 트래픽만 허용
  }

  egress { # outbound 규칙
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # 모든 프로토콜 허용
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.tag_header}-eks-sg" # 태그 이름 수정
  }
}

# ===============================================================================
# 2. k8s master 및 워커노드용 역할 및 정책 생성
# 클러스터용(k8s) 역할 생성
resource "aws_iam_role" "cluster_role" {
  name = "${local.tag_header}-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = { Service = "eks.amazonaws.com" }
      }
    ]
  })
  tags = { Name = "${local.tag_header}-cluster-role" }
}

# 역할에서 사용할 정책 생성
# 정책 연결: 콘솔(IAM - 정책 - AmazonEKSClusterPolicy의 ARN)
resource "aws_iam_role_policy_attachment" "cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster_role.id
}

# 워커노드용 역할 및 정책 생성
resource "aws_iam_role" "node_role" {
  name = "${local.tag_header}-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = { Service = "ec2.amazonaws.com" }
      }
    ]
  })
  tags = { Name = "${local.tag_header}-node-role" }
}

locals {
  node_policies = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    # ECR 레포지토리 이미지 읽기
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    # SSM: SSH 없이 터미널 접속 가능
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    # Logging: 파드 및 시스템 로그 전송
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
    # S3: 설정 파일이나 이미지 읽기 (필요 시 수정)
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  ]
}

resource "aws_iam_role_policy_attachment" "node_policy" {
  for_each   = toset(local.node_policies)
  policy_arn = each.value
  role       = aws_iam_role.node_role.id
}

# locals {
#   # 리스트를 선언함과 동시에 toset()으로 감싸서 Set 형태로 변수에 저장합니다.
#   node_policies = toset([
#     "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
#     "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
#     "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
#     "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
#     "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
#     "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
#   ])
# }
# resource "aws_iam_role_policy_attachment" "node_policy" {
#   # toset() 없이 변수 호출
#   for_each = local.node_policies

#   role       = aws_iam_role.eks_node_role.name
#   policy_arn = each.key 
# }

# ===============================================================================
# 3. EKS Cluster 리소스 생성
resource "aws_eks_cluster" "eks_cluster" {
  name = "${local.tag_header}-lab-eks-cluster"

  # 클러스터 역할
  role_arn = aws_iam_role.cluster_role.arn

  # 네트워크 설정
  vpc_config {
    # local.subnet_map을 순회하면서 type이 "Cluster"(또는 "private")인 서브넷의 ID만 추출하여 리스트로 만듭니다.
    subnet_ids = [
      for key, config in local.subnet_map : aws_subnet.subnet[key].id
      if config.type == "Cluster"
    ]
  }

  # 사용자 연결 설정
  access_config {
    # EKS 클러스터가 사용자나 역할을 어떤 방식으로 인식하게 할지 지정
    # API_AND_CONFIG_MAP / CounfigMap
    authentication_mode = "API_AND_CONFIG_MAP"
    # 생성자에게 자동으로 관리자 권한을 부여
    bootstrap_cluster_creator_admin_permissions = true
  }

  depends_on = [aws_iam_role_policy_attachment.cluster_policy]
}

# ===============================================================================
# 4. 노드 그룹 생성
# 밑 명령어로 필요한 이미지값 확인할 수 있음
# aws ssm get-parameter \
#     --name /aws/service/eks/optimized-ami/1.30/amazon-linux-2/recommended/image_id \
#     --query "Parameter.Value" \
#     --output text

data "aws_ami" "eks_al2023_latest" {
  most_recent = true
  owners      = ["602401143452"] # Amazon EKS 공식 계정

  filter {
    name = "name"
    # 'standard'를 명시하는 대신 와일드카드를 써서 1.35 버전의 x86_64 이미지를 찾습니다.
    values = ["amazon-eks-node-al2023-x86_64-standard-1.35-v*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_launch_template" "eks_launch_template" {
  name_prefix   = "${local.tag_header}-lab-eks-ng"
  image_id      = data.aws_ami.eks_al2023_latest.id
  instance_type = "t3.small"
  key_name      = "${local.tag_header}-key"

  # [수정 1] 보안 그룹 참조 수정
  # 주의: 아래 eks_sg와 external_alb_sg는 실제 security_group.tf 파일에 
  # 정의하신 리소스 이름(블록 이름)으로 맞춰주셔야 합니다.
  vpc_security_group_ids = [
    aws_security_group.eks_sg.id,          # 예: resource "aws_security_group" "eks_sg" {...}
    aws_security_group.external_alb_sg.id, # 예: resource "aws_security_group" "external_alb_sg" {...}
    aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id
  ]

  update_default_version = true

  # [수정 2] EKS 클러스터 참조 수정 (보간법 내부에 올바른 리소스 이름 명시)
  user_data = base64encode(<<-EOT
    ---
    apiVersion: node.eks.aws/v1alpha1
    kind: NodeConfig
    spec:
      cluster:
        name: ${aws_eks_cluster.eks_cluster.name}
        apiServerEndpoint: ${aws_eks_cluster.eks_cluster.endpoint}
        certificateAuthority: ${aws_eks_cluster.eks_cluster.certificate_authority[0].data}
        cidr: ${aws_eks_cluster.eks_cluster.kubernetes_network_config[0].service_ipv4_cidr}
  EOT
  )

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "${local.tag_header}-lab-eks-instance" }
  }

  tag_specifications {
    resource_type = "volume"
    tags          = { Name = "${local.tag_header}-lab-eks-volume" }
  }

  tags = { type = "k8s" }
}

resource "aws_eks_node_group" "eks_node_group" {
  node_group_name = "${local.tag_header}-lab-eks-node-group"

  # [수정 3] EKS 클러스터 이름 참조 수정
  cluster_name  = aws_eks_cluster.eks_cluster.name
  node_role_arn = aws_iam_role.node_role.arn

  # [수정 4] 서브넷 참조 수정 (이전 EKS 생성 시 사용했던 for_each 필터링 방식 적용)
  # 워커 노드가 배치될 서브넷의 type(예: "private" 또는 "Cluster")을 지정하세요.
  subnet_ids = [
    for key, config in local.subnet_map : aws_subnet.subnet[key].id
    if config.type == "private"
  ]

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  launch_template {
    name    = aws_launch_template.eks_launch_template.name
    version = aws_launch_template.eks_launch_template.latest_version
  }

  depends_on = [aws_iam_role_policy_attachment.node_policy]
}

# ===============================================================================
# [추가] 사용자 연결
# 밑에걸 aws cli에 입력해서 확인 가능
resource "null_resource" "update_kubeconfig" {
  depends_on = [aws_eks_node_group.eks_node_group]
  provisioner "local-exec" {
    # 클러스터 참조 방식 수정 (aws_eks_cluster.eks_cluster.name)
    command = "aws eks update-kubeconfig --region ap-southeast-1 --name ${aws_eks_cluster.eks_cluster.name}"
  }
}

# ===============================================================================
# 5. 사용자 등록
resource "aws_eks_access_entry" "bipa17_student" {
  # 테라폼 리소스 이름은 하이픈(-)보다 언더바(_)를 사용하는 것이 권장되어 bipa17-student -> bipa17_student 로 변경했습니다.

  # 클러스터 참조 방식 수정
  cluster_name = aws_eks_cluster.eks_cluster.name

  # 등록할 사용자의 계정 ARN
  principal_arn = "arn:aws:iam::925047940866:user/bipa17-instructor"

  # 아래와 같이 지정하고 사용자 계정을 IAM에서 역할 부여
  kubernetes_groups = ["master"]
  type              = "STANDARD"
}

resource "aws_eks_access_policy_association" "bipa17_student_admin" {
  # 클러스터 참조 방식 수정
  cluster_name = aws_eks_cluster.eks_cluster.name
  policy_arn   = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  # 위에서 변경한 access_entry 리소스 이름 반영
  principal_arn = aws_eks_access_entry.bipa17_student.principal_arn

  access_scope {
    type = "cluster" # 적용범위: 클러스터 전체
  }

  depends_on = [aws_eks_access_entry.bipa17_student]
}

# kubectl get node -o wide 입력해서 되는지 최종확인
# 콘솔
# SSM -> Fleet Manager 노드 있는지 확인
# EKS -> 컴퓨팅에 노드 있는 확인

# 5. 사용자 등록(반복문)

locals {
  admin = toset([
    "arn:aws:iam::925047940866:user/bipa17-instructor",
    "arn:aws:iam::925047940866:user/bipa17-student01",
    "arn:aws:iam::925047940866:user/bipa17-student04",
    "arn:aws:iam::925047940866:user/bipa17-student08",
    "arn:aws:iam::925047940866:user/bipa17-student09"
  ])
}

# resource "aws_eks_access_entry" "entry_admin" {
#   cluster_name = aws_eks_cluster.${local.tag_header}_lab_cluster.name
#   # 등록할 사용자의 계정 ARN
#   for_each = local.entry_admin_arn

#   principal_arn = each.value

#   # 아래와 같이 지정하고 사용자 계정을 IAM에서 역할 부여
#   # 원래 IAM 그룹명이 들어감 
#   kubernetes_groups = ["master"]
#   type              = "STANDARD"
# }

# resource "aws_eks_access_policy_association" "access_admin" {
#   cluster_name  = aws_eks_cluster.${local.tag_header}_lab_cluster.name
#   policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
#   principal_arn = aws_eks_access_entry.bipa17-student.principal_arn

#   access_scope {
#     type = "cluster" # 적용범위: 클러스터 전체
#   }

#   depends_on = [aws_eks_access_entry.bipa17-student]
# }

# kubectl get node -o wide 입력해서 되는지 최종확인
# 콘솔
# SSM -> Fleet Manager 노드 있는지 확인
# EKS -> 컴퓨팅에 노드 있는 확인
