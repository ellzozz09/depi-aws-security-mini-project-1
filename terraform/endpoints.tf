# 1 & 2. Security Group for Interface Endpoints
resource "aws_security_group" "endpoint_sg" {
  name        = "depi-sec-endpoint-sg"
  description = "Allow inbound HTTPS for VPC endpoints"
  vpc_id      = aws_vpc.app_vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "endpoint_https" {
  security_group_id = aws_security_group.endpoint_sg.id
  cidr_ipv4         = "10.0.0.0/16"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

# 3. S3 Gateway Endpoint and Route Table Association
resource "aws_vpc_endpoint" "s3_gateway" {
  vpc_id            = aws_vpc.app_vpc.id
  service_name      = "com.amazonaws.us-east-1.s3"
  vpc_endpoint_type = "Gateway"
}

resource "aws_vpc_endpoint_route_table_association" "private_s3_route" {
  route_table_id  = aws_route_table.private_rt.id # Ensure this matches your route table resource name
  vpc_endpoint_id = aws_vpc_endpoint.s3_gateway.id
}

# 4 & 5. SSM Interface Endpoints with Private DNS
locals {
  ssm_services = ["ssm", "ssmmessages", "ec2messages"]
}

resource "aws_vpc_endpoint" "ssm_endpoints" {
  for_each            = toset(local.ssm_services)
  vpc_id              = aws_vpc.app_vpc.id
  service_name        = "com.amazonaws.us-east-1.${each.key}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  security_group_ids  = [aws_security_group.endpoint_sg.id]
  private_dns_enabled = true
}