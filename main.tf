provider "aws" {
  region = "eu-west-2"
}

# Loading Ubuntu Amazon Machine Image to build the EC2 server
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  owners = ["099720109477"] # Canonical
}

# VPC - Use default VPC 
data "aws_vpc" "default" {
  default = true
}

# Security Group - Allow HTTP access from anywhere
resource "aws_security_group" "web_server_sg" {
  name        = "name-selection-app-sg"
  description = "Allow HTTP inbound traffic for web application"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "name-selection-app-security-group"
  }
}

resource "aws_instance" "app_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.web_server_sg.id]

  # Associate public IP so we can access the web app
  associate_public_ip_address = true

  # User data script to install web server and deploy app
  user_data = <<-EOF
              #!/bin/bash
              set -e
              
              # Update system
              apt-get update
              apt-get install -y nginx
              
              # Create directory for our app
              mkdir -p /var/www/html
              
              # Copy the app.html to nginx web root
              cat > /var/www/html/index.html << 'HTMLEOF'
              ${file("app.html")}
              HTMLEOF
              
              # Ensure nginx is started and enabled
              systemctl enable nginx
              systemctl start nginx
              EOF

  # User data changes force replacement
  user_data_replace_on_change = true

  tags = {
    Name        = "name-selection-app-server"
    Environment = "Development"
    ManagedBy   = "Terraform"
  }
}

# Outputs to easily access the application
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.app_server.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.app_server.public_ip
}

output "web_application_url" {
  description = "URL to access the web application"
  value       = "http://${aws_instance.app_server.public_ip}"
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.web_server_sg.id
}
