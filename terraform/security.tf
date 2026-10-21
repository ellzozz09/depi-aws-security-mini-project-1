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