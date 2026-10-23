# 1. ALB Security Group
resource "aws_security_group" "alb_sg" {
  name        = "depi-sec-alb-sg"
  description = "Allow inbound HTTP from anywhere"
  vpc_id      = aws_vpc.app_vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "alb_http_ingress" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

# 2. Application Security Group
resource "aws_security_group" "app_sg" {
  name        = "depi-sec-app-sg"
  description = "Allow inbound HTTP from ALB only"
  vpc_id      = aws_vpc.app_vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "app_http_ingress" {
  security_group_id            = aws_security_group.app_sg.id
  referenced_security_group_id = aws_security_group.alb_sg.id
  from_port                    = 80
  ip_protocol                  = "tcp"
  to_port                      = 80
}

# 3. Database Security Group
resource "aws_security_group" "db_sg" {
  name        = "depi-sec-db-sg"
  description = "Allow MySQL from App SG only"
  vpc_id      = aws_vpc.app_vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "db_mysql_ingress" {
  security_group_id            = aws_security_group.db_sg.id
  referenced_security_group_id = aws_security_group.app_sg.id
  from_port                    = 3306
  ip_protocol                  = "tcp"
  to_port                      = 3306
}

# 4. EFS Security Group
resource "aws_security_group" "efs_sg" {
  name        = "depi-sec-efs-sg"
  description = "Allow NFS from App SG only"
  vpc_id      = aws_vpc.app_vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "efs_nfs_ingress" {
  security_group_id            = aws_security_group.efs_sg.id
  referenced_security_group_id = aws_security_group.app_sg.id
  from_port                    = 2049
  ip_protocol                  = "tcp"
  to_port                      = 2049
}

# Universal Egress (Required when using standalone ingress rules in AWS provider v5)
resource "aws_vpc_security_group_egress_rule" "alb_egress_all" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule" "app_egress_all" {
  security_group_id = aws_security_group.app_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule" "db_egress_all" {
  security_group_id = aws_security_group.db_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule" "efs_egress_all" {
  security_group_id = aws_security_group.efs_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# NACL
resource "aws_network_acl" "private_nacl" {
  vpc_id     = aws_vpc.app_vpc.id
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  # Inbound Rule 100: Allow HTTP from VPC
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "10.0.0.0/16"
    from_port  = 80
    to_port    = 80
  }

  # Inbound Rule 110: Allow HTTPS from VPC
  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "10.0.0.0/16"
    from_port  = 443
    to_port    = 443
  }

  # Inbound Rule 120: Allow Ephemeral Return Traffic from VPC
  ingress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = "10.0.0.0/16"
    from_port  = 1024
    to_port    = 65535
  }

  # Inbound Rule 200: Explicit Deny SSH
  ingress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }

  # Outbound Rule 100: Allow all internal VPC traffic
  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "10.0.0.0/16"
    from_port  = 0
    to_port    = 0
  }

  # Outbound Rule 110: Allow HTTPS externally
  egress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  tags = {
    Name = "depi-sec-private-nacl"
  }
}