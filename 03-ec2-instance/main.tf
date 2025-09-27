# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Get the default VPC information
data "aws_vpc" "selected" {
  id = var.vpc_id
}

# Get the first public subnet in the VPC
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
  
  filter {
    name   = "map-public-ip-on-launch"
    values = ["true"]
  }
}

# Get the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Security group for web server
resource "aws_security_group" "web_sg" {
  name        = "web-server-sg"
  description = "Security group for web server allowing HTTP and SSH"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

# EC2 instance
resource "aws_instance" "web_server" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  subnet_id              = data.aws_subnets.public.ids[0]
  
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              
              # Create custom index.html
              cat > /var/www/html/index.html <<'EOL'
              <!DOCTYPE html>
              <html lang="en">
              <head>
                  <meta charset="UTF-8">
                  <meta name="viewport" content="width=device-width, initial-scale=1.0">
                  <title>Welcome to My Web Server</title>
                  <style>
                      body {
                          font-family: Arial, sans-serif;
                          margin: 0;
                          padding: 0;
                          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                          height: 100vh;
                          display: flex;
                          justify-content: center;
                          align-items: center;
                      }
                      .container {
                          text-align: center;
                          background: white;
                          padding: 40px;
                          border-radius: 10px;
                          box-shadow: 0 10px 30px rgba(0,0,0,0.2);
                      }
                      h1 {
                          color: #333;
                          margin-bottom: 20px;
                      }
                      p {
                          color: #666;
                          font-size: 18px;
                      }
                      .success {
                          color: #28a745;
                          font-weight: bold;
                      }
                  </style>
              </head>
              <body>
                  <div class="container">
                      <h1>🚀 Welcome to My Web Server!</h1>
                      <p>This server was deployed using <span class="success">Terraform</span></p>
                      <p>Apache is running successfully on Amazon Linux 2</p>
                      <p>Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)</p>
                      <p>Availability Zone: $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)</p>
                  </div>
              </body>
              </html>
              EOL
              
              # Set proper permissions
              chown apache:apache /var/www/html/index.html
              chmod 644 /var/www/html/index.html
              
              # Restart Apache to apply changes
              systemctl restart httpd
              EOF

  tags = merge(var.tags, {
    Name = "web-server"
  })

  # Ensure the instance gets a public IP
  associate_public_ip_address = true
}

# Elastic IP for the instance (optional but recommended)
resource "aws_eip" "web_eip" {
  instance = aws_instance.web_server.id
  domain   = "vpc"
  
  tags = merge(var.tags, {
    Name = "web-server-eip"
  })
}