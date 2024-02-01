provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = "us-east-1"
}
############################### VPC ########################################################
resource "aws_vpc" "eks_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Netflix-eks-vpc"
  }
}
######################## PUBLIC SUBNETS #######################################################
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"  # Replace with your desired availability zone
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"  # Replace with your desired availability zone
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-2"
  }
}


# Create private subnets
resource "aws_subnet" "private_subnet_1" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = "10.0.3.0/24"  # Replace with your desired CIDR block for the first private subnet
  availability_zone       = "us-east-1a"    # Replace with your desired availability zone for the first private subnet
  map_public_ip_on_launch = false           # Set to false for private subnets

  tags = {
    Name = "private-subnet-1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = "10.0.4.0/24"  # Replace with your desired CIDR block for the second private subnet
  availability_zone       = "us-east-1b"    # Replace with your desired availability zone for the second private subnet
  map_public_ip_on_launch = false           # Set to false for private subnets

  tags = {
    Name = "private-subnet-2"
  }
}

################## IGW #######################
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.eks_vpc.id
}
################## NGW #######################
resource "aws_nat_gateway" "ngw" {
  subnet_id     = aws_subnet.public_subnet_1.id
  allocation_id = aws_eip.elastic-ip.id
}
################# EIP ########################
resource "aws_eip" "elastic-ip" {
  domain = "vpc"
  
}
############### ROUTE TABLE ################
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.eks_vpc.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.eks_vpc.id
}

############# Routes #########################
resource "aws_route" "igw_route" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route" "private_ngw" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.ngw.id
}
############ Association #######################
resource "aws_route_table_association" "public1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private.id
}


################################ EKS ROLE #################################

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# IAM role for EKS cluster
resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "eks.amazonaws.com",
      },
    }],
  })
}

# Attach policies to the EKS cluster role
resource "aws_iam_role_policy_attachment" "eks_cluster_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}
############################### NODES ROLE #########################################
# IAM role for EKS nodes
resource "aws_iam_role" "eks_nodes_role" {
  name = "eks-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com",
      },
    }],
  })
}

# Attach policies to the EKS nodes role
resource "aws_iam_role_policy_attachment" "eks_nodes_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodes_role.name
}

resource "aws_iam_role_policy_attachment" "example-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodes_role.name
}

resource "aws_iam_role_policy_attachment" "example-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodes_role.name
}


######################### CLUSTER PROVISION #####################################

# EKS cluster provision
resource "aws_eks_cluster" "netflix-cluster" {
  name     = "netflix-eks"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id, aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
  }
}

################################## NODE PROVISION ################################

# EKS Node Group
resource "aws_eks_node_group" "netflix-node" {
  cluster_name    = aws_eks_cluster.netflix-cluster.name
  node_group_name = "netflix-node-group"

  node_role_arn = aws_iam_role.eks_nodes_role.arn

  subnet_ids = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  instance_types = ["t2.large"]  # Specify the EC2 instance type

  depends_on = [aws_eks_cluster.netflix-cluster]
}