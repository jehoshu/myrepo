provider "aws" {
  region = "us-west-2" # Change to your desired region
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "main-vpc"
  }
}

resource "aws_subnet" "public" {
  count                   = 2 # Creating two public subnets in different AZs
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  map_public_ip_on_launch = true
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  tags = {
    Name = "public-subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "private" {
  count             = 2 # Creating two private subnets in different AZs
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + 2)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  tags = {
    Name = "private-subnet-${count.index + 1}"
  }
}

data "aws_availability_zones" "available" {}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name = "public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public.id
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.main.id
  subnet_id     = element(aws_subnet.public.*.id, 0) # Assuming NAT Gateway in the first public subnet
  tags = {
    Name = "main-nat-gateway"
  }
}

resource "aws_eip" "main" {
  vpc = true
  tags = {
    Name = "main-eip"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }
  tags = {
    Name = "private-rt"
  }
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "main" {
  vpc_id = aws_vpc.main.id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0", "192.168.1.10/32"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "main-sg"
  }
}

resource "aws_security_group_rule" "port_80_rule" {
  for_each = toset(["0.0.0.0/0", "192.168.1.4/32"])
  type = "ingress"
  from_port = 80
  to_port = 80
  protocol = "tcp"
  cidr_block = [each.value]
  security_group_id = aws_security_group.main-sg.id
}

resource "aws_security_group_rule" "port_443_rule" {
  type = "ingress"
  from_port = 443
  to_port = 443
  protocol = "tcp"
  cidr_block = ["0.0.0.0/0"]
  security_group_id = aws_security_group.main-sg.id
}

resource "aws_security_group_rule" "port_80_rule" {
  type = "egress"
  from_port = 80
  to_port = 80
  protocol = "tcp"
  cidr_block = ["0.0.0.0/0"]
  security_group_id = aws_security_group.main-sg.id
}

resource "aws_security_group_rule" "port_443_rule" {
  type = "egress"
  from_port = 443
  to_port = 443
  protocol = "tcp"
  cidr_block = ["0.0.0.0/0"]
  security_group_id = aws_security_group.main-sg.id
}

# IAM rule and polices

resource "aws_iam_role" "ec2_role" {
  name = "ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "ec2_policy" {
  name        = "ec2-policy"
  description = "Policy for EC2 instances to access S3 and CloudWatch"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:*",
          "cloudwatch:*",
          "logs:*"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_policy_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_policy.arn
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}
