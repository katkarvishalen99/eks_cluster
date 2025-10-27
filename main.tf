
#==========================VPC==================================
resource "aws_vpc" "eks_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "eks-vpc"
  }
}
#=========================internet gateway=====================

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.eks_vpc.id
    tags = {
      Name = "eks-igw"
    }
}
#========================public Subnet================================
resource "aws_subnet" "public_subnet_a" {
    vpc_id                  = aws_vpc.eks_vpc.id
    cidr_block              = var.cidr_subnet_a
    availability_zone       = "${var.region}a"
    map_public_ip_on_launch = true
    tags = {
      Name = "eks-public-subnet-a"
    }
}

resource "aws_subnet" "public_subnet_b" {
    vpc_id                  = aws_vpc.eks_vpc.id
    cidr_block              = var.cidr_subnet_b
    availability_zone       = "${var.region}b"
    map_public_ip_on_launch = true
    tags = {
      Name = "eks-public-subnet-b"
    } 
}

#=======================route table=================================
resource "aws_route_table" "public_rt" {
    vpc_id = aws_vpc.eks_vpc.id
    route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.igw.id
    }
    tags = {
      Name = "eks-public-rt"
    }
  }

#======================route table association=====================
resource "aws_route_table_association" "public_a" {
    subnet_id      = aws_subnet.public_subnet_a.id
    route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_b" {
   subnet_id      = aws_subnet.public_subnet_b.id
   route_table_id = aws_route_table.public_rt.id
}

#=====================IAM role for EKS cluster====================
resource "aws_iam_role" "eks_cluster_role" {
    name = "eksClusterRole"
    assume_role_policy = "${file("eks_cluster_role.json")}"
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
    role       = aws_iam_role.eks_cluster_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

#===================EKS cluster==================================
resource "aws_eks_cluster" "eks_cluster" {
    name     = "eks-cluster"
    role_arn = aws_iam_role.eks_cluster_role.arn

    vpc_config {
    subnet_ids = [
      aws_subnet.public_subnet_a.id,
      aws_subnet.public_subnet_b.id
     ]
    }

    version = var.eks_version

    depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
}

#=================IAM ROle for Node group=======================
resource "aws_iam_role" "eks_node_role" {
    name = "eksNodeRole"
    assume_role_policy = "${file("ec2_role.json")}"
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
    role       = aws_iam_role.eks_node_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
    role       = aws_iam_role.eks_node_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "ec2_container_registry_read_only" {
    role       = aws_iam_role.eks_node_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

#================Node group configuration======================
resource "aws_eks_node_group" "eks_nodes" {
    cluster_name    = aws_eks_cluster.eks_cluster.name
    node_group_name = "eks-node-group"
    node_role_arn   = aws_iam_role.eks_node_role.arn
    subnet_ids      = [
      aws_subnet.public_subnet_a.id,
      aws_subnet.public_subnet_b.id
     ]

    scaling_config {
      desired_size = 2
      max_size     = 3
      min_size     = 1
    }

    instance_types = ["t3.small"]
    
    depends_on = [
      aws_iam_role_policy_attachment.eks_worker_node_policy,
      aws_iam_role_policy_attachment.eks_cni_policy,
      aws_iam_role_policy_attachment.ec2_container_registry_read_only
    ]
}
