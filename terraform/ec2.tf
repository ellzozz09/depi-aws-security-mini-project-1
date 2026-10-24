# 1. Dynamically fetch the latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# 2. Web Server in Availability Zone A
resource "aws_instance" "web_a" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.private_a.id # Ensure this matches your subnet resource name
  vpc_security_group_ids      = [aws_security_group.app_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name # Attaches the IAM role from Task 3
  associate_public_ip_address = false
  
  # By completely omitting the 'key_name' argument, we prevent SSH key attachment entirely

  user_data = <<-EOF
    #!/bin/bash
    dnf update -y
    dnf install -y nginx
    systemctl enable --now nginx
    
    # Securely retrieve the Availability Zone using IMDSv2
    TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
    AZ=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone)
    
    echo "<h1>Response served securely from AZ: $AZ</h1>" > /usr/share/nginx/html/index.html
  EOF

  tags = {
    Name = "depi-sec-web-a"
  }
}

# 3. Web Server in Availability Zone B
resource "aws_instance" "web_b" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.private_b.id # Ensure this matches your subnet resource name
  vpc_security_group_ids      = [aws_security_group.app_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = false

  user_data = <<-EOF
    #!/bin/bash
    dnf update -y
    dnf install -y nginx
    systemctl enable --now nginx
    
    TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
    AZ=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone)
    
    echo "<h1>Response served securely from AZ: $AZ</h1>" > /usr/share/nginx/html/index.html
  EOF

  tags = {
    Name = "depi-sec-web-b"
  }
}