############################################################################################
//Configuration of the AWS VPC for ROSA
############################################################################################

module "vpc" {
  source             = "terraform-aws-modules/vpc/aws"
  version            = "5.19.0"
  name               = var.new_vpc_name
  cidr               = var.new_vpc_cidr
  enable_nat_gateway = true
}


############################################################################################
//Creation of AWS Public Subnet for ROSA
############################################################################################

//Gathering the availability zones
data "aws_availability_zones" "available" {}

resource "aws_subnet" "public_subnet_cidr" {
  vpc_id                  = module.vpc.vpc_id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]
  tags = {
    Name = var.public_subnet_name
  }
}

############################################################################################
//Creation of AWS Private Subnet for ROSA
############################################################################################

resource "aws_subnet" "private_subnet_cidr" {
  vpc_id                  = module.vpc.vpc_id
  cidr_block              = var.private_subnet_cidr
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[0]
  tags = {
    Name = var.private_subnet_name
  }
}

############################################################################################
//Creation of AWS Internet Gateway for ROSA
############################################################################################
resource "aws_internet_gateway" "rosa_gateway" {
  vpc_id = module.vpc.vpc_id
  tags = {
    Name = var.rosa_gateway_name
  }
}

resource "aws_route_table" "rosa" {
  vpc_id = module.vpc.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.rosa_gateway.id
  }
}

resource "aws_route_table_association" "rt_table_assoc_igw" {
  subnet_id      = aws_subnet.public_subnet_cidr.id
  route_table_id = aws_route_table.rosa.id
}


############################################################################################
//EIP for NAT Gateway for the public subnet
############################################################################################

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "nat-eip-for-rosa"
  }
}

############################################################################################
//Creation of the NAT Gateway for the public subnet
############################################################################################

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.private_subnet_cidr.id

  tags = {
    Name = "nat-gateway-for-rosa"
  }
}

############################################################################################
//Update of the Route table for the private subnet using the NAT Gateway
############################################################################################

resource "aws_route_table" "private" {
  vpc_id = module.vpc.vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "private-route-table"
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private_subnet_cidr.id
  route_table_id = aws_route_table.private.id
}

############################################################################################
//Creation S3 Endpoint for ROSA VPC //Add the private subnet to the route table - To be done
############################################################################################

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  tags = {
    Name = "s3-endpoint"
  }
}

resource "aws_route_table_association" "rt_table_assoc_s3_endpoint" {
  subnet_id      = aws_subnet.private_subnet_cidr.id
  route_table_id = aws_route_table.private.id
}

############################################################################################
//Creation EC2 Endpoint for ROSA VPC 
############################################################################################
resource "aws_vpc_endpoint" "ec2" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.ec2"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.private_subnet_cidr.id]

  tags = {
    Name = "ec2-endpoint"
  }
}

############################################################################################
//Creation ELB Endpoint for ROSA VPC 
############################################################################################
resource "aws_vpc_endpoint" "elb" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.elasticloadbalancing"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.private_subnet_cidr.id]
  tags = {
    Name = "elb-endpoint"
  }
}

############################################################################################
//Creation ROSA Cluster
############################################################################################

module "rosa-classic" {
  source  = "terraform-redhat/rosa-classic/rhcs"
  version = "1.6.5"

  cluster_name           = var.cluster_name
  openshift_version      = var.openshift_version
  machine_cidr           = module.vpc.vpc_cidr_block
  create_account_roles   = true
  create_operator_roles  = true
  create_oidc            = true
  aws_subnet_ids         = concat(module.vpc.public_subnets, module.vpc.private_subnets)
  aws_availability_zones = [data.aws_availability_zones.available.names[0]]
  multi_az               = false
  replicas               = 3
  compute_machine_type   = var.compute_machine_type
}

############################################################################################
//Creation of idp htpasswd for ROSA Cluster - To be done
############################################################################################
resource "rhcs_identity_provider" "htpasswd_idp" {
  cluster = module.rosa-classic.cluster_id
  name    = "htpasswd"
  htpasswd = {
    users = [{
      username = var.htpasswd_idp_user
      password = var.htpasswd
      }
    ]
  }
}



############################################################################################
//Creation of AWS S3 Bucket for ROSA Cluster
############################################################################################

module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.6.0"

  bucket = var.bucket_name
  acl    = var.acl

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  versioning = {
    enabled = true
  }
}

############################################################################################
//End of main.tf
############################################################################################