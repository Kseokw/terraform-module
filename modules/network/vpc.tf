# VPC 생성
# 여기서 리소스명에 this를 쓰면 되는 경우와 쓰면 안되는 경우를 설명하시오
resource "aws_vpc" "this" {
  cidr_block           = local.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"

  tags = {
    Name = "${local.tag_header}-network-vpc"
  }
}

# 

# 서브넷 생성
# resource "aws_subnet" "subnet" {
#   for_each = local.subnet_map

#   vpc_id            = aws_vpc.this.id
#   cidr_block        = each.value.cidr
#   availability_zone = each.value.az

#   enable_resource_name_dns_a_record_on_launch = true

#   map_public_ip_on_launch = each.value.type == "public" ? true : false


#   tags = merge(
#     # 1. 공통 태그 (Public, Private, Cluster 모두 기본으로 들어감)
#     {
#       "Name" = "${local.tag_header}-${each.key}-subnet"
#       "Type" = each.value.type
#     },

#     # 2. Public 서브넷일 경우에만 합쳐지는(Merge) 태그
#     each.value.type == "public" ? {
#       "kubernetes.io/cluster/본인의-EKS-클러스터-이름" = "shared"
#       "kubernetes.io/role/elb"                = "1"
#     } : {},

#     # 3. Cluster 서브넷일 경우에만 합쳐지는(Merge) 태그
#     each.value.type == "Cluster" ? {
#       "kubernetes.io/cluster/본인의-EKS-클러스터-이름" = "shared"
#       "kubernetes.io/role/internal-elb"       = "1"
#     } : {}
#   )
# }

# 수동 생성
resource "aws_subnet" "public_1a_subnet" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-southeast-1a"

  # Public Subnet 설정
  map_public_ip_on_launch                     = true # 퍼블릭 IPv4 주소 자동 할당
  enable_resource_name_dns_a_record_on_launch = true # 리소스 이름 DNS A 레코드

  tags = {
    Name = "${local.tag_header}-public-1a-subnet"
  }
}

resource "aws_subnet" "public_1b_subnet" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-southeast-1a"

  # Public Subnet 설정
  map_public_ip_on_launch                     = true # 퍼블릭 IPv4 주소 자동 할당
  enable_resource_name_dns_a_record_on_launch = true # 리소스 이름 DNS A 레코드

  tags = {
    Name = "${local.tag_header}-public-1b-subnet"
  }
}

resource "aws_subnet" "public_1c_subnet" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "ap-southeast-1a"

  # Public Subnet 설정
  map_public_ip_on_launch                     = true # 퍼블릭 IPv4 주소 자동 할당
  enable_resource_name_dns_a_record_on_launch = true # 리소스 이름 DNS A 레코드

  tags = {
    Name = "${local.tag_header}-public-1c-subnet"
  }
}

# ========================================================================================
# private 서브넷 생성
resource "aws_subnet" "priv_1a_subnet" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "ap-southeast-1a"

  tags = {
    Name = "${local.tag_header}priv-1a-subnet"
  }
}

resource "aws_subnet" "priv_1b_subnet" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.0.12.0/24"
  availability_zone = "ap-southeast-1a"

  tags = {
    Name = "${local.tag_header}priv-1b-subnet"
  }
}


resource "aws_subnet" "priv_1c_subnet" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.0.13.0/24"
  availability_zone = "ap-southeast-1a"

  tags = {
    Name = "${local.tag_header}priv-1c-subnet"
  }
}

# NAT Gateway 생성
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  # NAT Gateway를 생성할 Public Subnet 지정
  subnet_id  = aws_subnet.public_1a_subnet.id
  depends_on = [aws_internet_gateway.igw] # NAT Gateway 생성 시점에 IGW가 생성되어 있으면 생성/의존성
  tags = {
    Name = "${local.tag_header}-nat-gw"
  }
}

# =======================================================================================================
# gateway 생성
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${local.tag_header}-igw"
  }
}

# NAT Gateway 생성을 위한 EIP 생성
resource "aws_eip" "nat_eip" {
  domain = "vpc" # VPC용 EIP 생성, std07-nat-eip의 사용범위를 VPC로 제한

  tags = {
    Name = "${local.tag_header}-nat-eip"
  }
}

# # NAT Gateway 생성
# resource "aws_nat_gateway" "nat_gw" {
#   allocation_id = aws_eip.nat_eip.id
#   # NAT Gateway를 생성할 Public Subnet 지정
#   # 결국 여기 들어가야할 값 subnet_id = aws_subnet.public1a.id
#   subnet_id  = aws_subnet.subnet["public${split("-", local.azs[0])[2]}"].id
#   depends_on = [aws_internet_gateway.igw] # NAT Gateway 생성 시점에 IGW가 생성되어 있으면 생성/의존성
#   tags = {
#     Name = "${local.tag_header}-nat-gw"
#   }
# }


# =======================================================================================================
# Route table 생성
# 1번. 라우트테이블을 다 만들고 연결해
# 2번. 타입 별로 라우트테이블을 따로 만들어
# 3번. 3항 연산자를 써서 public이면 하나를 만들면서 igw에 라우팅을걸어 -> private면 가용영역별로 만들면서 nat에 라우팅을 걸어 -> cluster면 하나를 만들면서 nat에 라우팅을 걸어
# resource "aws_route_table" "route_table" {
#   for_each = toset(local.subnet_type)

#   if each.value == "private" ? for
#   vpc_id   = aws_vpc.this.id
#   tags = {
#     Name = "${local.tag_header}-${each.value}-rt"
#   }
# }

# merge([action "" "name" {

# }])


resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.this.id
  route { # 라우팅테이블 생성하면서 라우팅 지정
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "${local.tag_header}-public-rt"
  }
}

resource "aws_route_table" "private1a_rt" {
  vpc_id = aws_vpc.this.id
  route { # 라우팅테이블 생성하면서 라우팅 지정
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gw.id
  }
  tags = {
    Name = "${local.tag_header}-private1a-rt"
  }
}

resource "aws_route_table" "private1b_rt" {
  vpc_id = aws_vpc.this.id
  route { # 라우팅테이블 생성하면서 라우팅 지정
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gw.id
  }
  tags = {
    Name = "${local.tag_header}-private1b-rt"
  }
}

resource "aws_route_table" "private1c_rt" {
  vpc_id = aws_vpc.this.id
  route { # 라우팅테이블 생성하면서 라우팅 지정
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gw.id
  }
  tags = {
    Name = "${local.tag_header}-private1c-rt"
  }
}

resource "aws_route_table" "cluster_rt" {
  vpc_id = aws_vpc.this.id
  route { # 라우팅테이블 생성하면서 라우팅 지정
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gw.id
  }
  tags = {
    Name = "${local.tag_header}-cluster-rt"
  }
}

resource "aws_route_table_association" "public1a_rt_association" {
  subnet_id      = aws_subnet.public_1a_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public1b_rt_association" {
  subnet_id      = aws_subnet.public_1b_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public1c_rt_association" {
  subnet_id      = aws_subnet.public_1c_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "priv1a_rt_association" {

  subnet_id      = aws_subnet.priv1a_subnet.id
  route_table_id = aws_route_table.private1a_rt.id
}
resource "aws_route_table_association" "priv1a_rt_association" {

  subnet_id      = aws_subnet.priv1a_subnet.id
  route_table_id = aws_route_table.std07_private_1a_rt.id
}
resource "aws_route_table_association" "priv1a_rt_association" {

  subnet_id      = aws_subnet.priv1a_subnet.id
  route_table_id = aws_route_table.std07_private_1a_rt.id
}
resource "aws_route_table_association" "std07_private_1a_rt_association" {

  subnet_id      = aws_subnet.std07_lab_priv_1a_subnet.id
  route_table_id = aws_route_table.std07_private_1a_rt.id
}
