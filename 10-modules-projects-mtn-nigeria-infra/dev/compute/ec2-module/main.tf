# Data sources
data "aws_ami" "amazon_linux_2" {
  count = var.ami_id == null ? 1 : 0

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

data "aws_vpc" "selected" {
  id = var.vpc_id
}

data "aws_subnet" "selected" {
  id = var.subnet_id
}

# Generate SSH key pair if not provided
resource "tls_private_key" "this" {
  count = var.key_name == null ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated" {
  count = var.key_name == null ? 1 : 0

  key_name_prefix = "${var.project_name}-${var.environment}-"
  public_key      = tls_private_key.this[0].public_key_openssh

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-keypair"
  })
}

# Security group
resource "aws_security_group" "ec2_sg" {
  count = length(var.security_group_ids) == 0 ? 1 : 0

  name_prefix = "${var.project_name}-${var.environment}-sg-"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.additional_security_group_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = ingress.value.description
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# EC2 instance
resource "aws_instance" "this" {
  ami = coalesce(var.ami_id, try(data.aws_ami.amazon_linux_2[0].id, ""))

  instance_type = var.instance_type
  subnet_id     = var.subnet_id

  key_name = coalesce(var.key_name, try(aws_key_pair.generated[0].key_name, null))

  vpc_security_group_ids = length(var.security_group_ids) > 0 ? var.security_group_ids : [aws_security_group.ec2_sg[0].id]

  associate_public_ip_address = var.associate_public_ip_address

  iam_instance_profile = var.iam_instance_profile

  user_data                   = var.user_data
  user_data_base64           = var.user_data_base64
  user_data_replace_on_change = false

  monitoring = var.enable_detailed_monitoring

  disable_api_termination = var.disable_api_termination

  # Root block device
  root_block_device {
    volume_size = var.root_volume_size
    volume_type = var.root_volume_type
    encrypted   = true

    tags = merge(var.tags, {
      Name = "${var.instance_name}-root-volume"
    })
  }

  # Additional EBS volumes
  dynamic "ebs_block_device" {
    for_each = var.additional_ebs_volumes
    content {
      device_name = ebs_block_device.value.device_name
      volume_size = ebs_block_device.value.volume_size
      volume_type = ebs_block_device.value.volume_type
      encrypted   = ebs_block_device.value.encrypted
      kms_key_id  = ebs_block_device.value.kms_key_id
    }
  }

  tags = merge(var.tags, {
    Name = var.instance_name
  })

  lifecycle {
    ignore_changes = [
      ami,
      user_data_replace_on_change,
    ]
  }
}

# EBS volume attachments for additional volumes not defined in the instance block
resource "aws_volume_attachment" "additional_volumes" {
  for_each = { for vol in var.additional_ebs_volumes : vol.device_name => vol if vol.device_name != null }

  device_name = each.value.device_name
  volume_id   = aws_ebs_volume.additional[each.key].id
  instance_id = aws_instance.this.id
}

resource "aws_ebs_volume" "additional" {
  for_each = { for vol in var.additional_ebs_volumes : vol.device_name => vol if vol.device_name != null }

  availability_zone = data.aws_subnet.selected.availability_zone
  size              = each.value.volume_size
  type              = each.value.volume_type
  encrypted         = each.value.encrypted
  kms_key_id        = each.value.kms_key_id

  tags = merge(var.tags, {
    Name = "${var.instance_name}-${each.value.device_name}"
  })
}