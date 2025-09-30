module "web_server" {
  source = "./ec2-module"

  project_name  = "demo-project"
  environment   = "dev"
  instance_name = "liontech"

  instance_type = "t2.micro"
  
  vpc_id    = "vpc-06c92c023ec2960be"
  subnet_id = "subnet-0c02df264d7a3c838"

  associate_public_ip_address = true

  additional_security_group_rules = [
    {
      type        = "ingress"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow HTTP access"
    },
    {
      type        = "ingress"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow HTTPS access"
    }
  ]

  root_volume_size = 30
  root_volume_type = "gp3"

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>Hello from $(hostname -f)</h1>" > /var/www/html/index.html
  EOF

  tags = {
    Component = "web"
    Owner     = "devops-team"
  }
}

output "web_server_public_ip" {
  value = module.web_server.instance_public_ip
}