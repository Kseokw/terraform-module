# VPC 생성
# 여기서 리소스명에 this를 쓰면 되는 경우와 쓰면 안되는 경우를 설명하시오
resource "aws_vpc" "vpc" {
  cidr_block           = local.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"

  tags = {
    Name = "${local.tag_header}-network-vpc"
  }
}


# 서브넷 생성
resource "aws_subnet" "subnet" {
  for_each = local.subnet_map

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  enable_resource_name_dns_a_record_on_launch = true

  map_public_ip_on_launch = each.value.type == "public" ? true : false


  tags = merge(
    # 1. 공통 태그 (Public, Private, Cluster 모두 기본으로 들어감)
    {
      "Name" = "${local.tag_header}-${each.key}-subnet"
      "Type" = each.value.type
    },

    # 2. Public 서브넷일 경우에만 합쳐지는(Merge) 태그
    each.value.type == "public" ? {
      "kubernetes.io/cluster/본인의-EKS-클러스터-이름" = "shared"
      "kubernetes.io/role/elb"                = "1"
    } : {},

    # 3. Cluster 서브넷일 경우에만 합쳐지는(Merge) 태그
    each.value.type == "Cluster" ? {
      "kubernetes.io/cluster/본인의-EKS-클러스터-이름" = "shared"
      "kubernetes.io/role/internal-elb"       = "1"
    } : {}
  )
}



# =======================================================================================================
# gateway 생성
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

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

# NAT Gateway 생성
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  # NAT Gateway를 생성할 Public Subnet 지정
  # 결국 여기 들어가야할 값 subnet_id = aws_subnet.public1a.id
  subnet_id = aws_subnet.subnet["public${split("-", local.az_names[0])[2]}"].id
  # subnet_id  = aws_subnet.subnet["public1a"].id
  depends_on = [aws_internet_gateway.igw] # NAT Gateway 생성 시점에 IGW가 생성되어 있으면 생성/의존성
  tags = {
    Name = "${local.tag_header}-nat-gw"
  }
}


# =======================================================================================================
# Route table 생성
# 1. Public 서브넷용 Route Table 생성 (IGW 연결)
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "${local.tag_header}-public-rt"
  }
}

# 2. Private/Cluster 서브넷용 Route Table 생성 (NAT Gateway 연결)
# NAT Gateway가 1개이므로 1개의 라우트 테이블을 모든 Private 서브넷이 공유합니다.

resource "aws_route_table" "private_rt" {
  for_each = toset(local.az_names)
  vpc_id   = aws_vpc.vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }
  tags = {
    Name = "${local.tag_header}-private${split("-", each.key)[2]}-rt"
  }
}

resource "aws_route_table" "cluster_rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }
  tags = {
    Name = "${local.tag_header}-cluster-rt"
  }
}

# 3. Route Table Association (서브넷과 라우트 테이블 연결)
# local.subnet_map을 순회하면서 type에 따라 알맞은 라우트 테이블을 매핑합니다.
resource "aws_route_table_association" "subnet_association" {
  for_each = local.subnet_map

  subnet_id = aws_subnet.subnet[each.key].id

  # type이 "public"이면 public 라우트 테이블을, 아니면 private 라우트 테이블을 연결
  route_table_id = (each.value.type == "public" ? aws_route_table.public_rt.id :
    each.value.type == "private" ? aws_route_table.private_rt[each.value.az].id : aws_route_table.cluster_rt.id
  )
}
