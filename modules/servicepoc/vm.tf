locals {
  service_names = [
    "com.amazonaws.${var.region}.ssm",
    "com.amazonaws.${var.region}.ssmmessages",
    "com.amazonaws.${var.region}.ec2messages"
  ]
  core_network_id = "core-network-0d589a04cfd762b9f"
}

resource "aws_security_group" "sg_ssm" {
  name   = "${var.name}-ssm-security-group"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "sg" {
  name   = "${var.name}-vpc-security-group"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "ssm_role" {
  name = "${var.name}-vpc-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.name}-vpc-ssm-role"
  }
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.ssm_role.name
}

resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = "${var.name}-vpc-ssm-instance-profile"
  role = aws_iam_role.ssm_role.name
}

resource "aws_vpc_endpoint" "ssm_servicesa" {
  count = length(local.service_names)

  vpc_id              = aws_vpc.vpc.id
  service_name        = local.service_names[count.index]
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.sg_ssm.id]
  private_dns_enabled = true
  subnet_ids = [
    for subnet in aws_subnet.subnets : subnet.id
  ]
}

resource "aws_instance" "instance" {
  count = length(aws_subnet.subnets)

  ami                    = "ami-00706d218fa27caea"
  instance_type          = "t3a.micro"
  iam_instance_profile   = aws_iam_instance_profile.ssm_instance_profile.name
  subnet_id              = aws_subnet.subnets[count.index].id
  vpc_security_group_ids = [aws_security_group.sg.id]
  user_data              = <<-EOF
            #!/bin/bash
            mkdir /var/www
            cd /var/www
            echo "<h1>Hello from $(hostname -f) in ${var.name}</h1>" > index.html
            python3 -m http.server 80 --bind 0.0.0.0 &
            EOF
  source_dest_check      = true

  tags = {
    Name = "${var.name}-instance-az${count.index + 1}"
  }
}
