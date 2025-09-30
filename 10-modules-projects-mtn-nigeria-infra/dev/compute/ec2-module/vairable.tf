# Required variables
variable "project_name" {
  description = "Name of the project for resource tagging"
  type        = string
}

variable "environment" {
  description = "Environment (e.g., dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "instance_name" {
  description = "Name prefix for the EC2 instance"
  type        = string
}

# EC2 Configuration
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "AMI ID to use for the instance. If not provided, latest Amazon Linux 2 AMI will be used"
  type        = string
  default     = null
}

variable "key_name" {
  description = "Name of an existing EC2 Key Pair to associate with the instance"
  type        = string
  default     = null
}

# Networking
variable "vpc_id" {
  description = "VPC ID where the instance will be launched"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where the instance will be launched"
  type        = string
}

variable "associate_public_ip_address" {
  description = "Whether to associate a public IP address with the instance"
  type        = bool
  default     = false
}

# Security Groups
variable "security_group_ids" {
  description = "List of security group IDs to attach to the instance"
  type        = list(string)
  default     = []
}

variable "additional_security_group_rules" {
  description = "Additional security group rules to create if creating new security group"
  type = list(object({
    type        = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = []
}

# Storage
variable "root_volume_size" {
  description = "Size of the root volume in GB"
  type        = number
  default     = 20
}

variable "root_volume_type" {
  description = "Type of the root volume (gp2, gp3, io1, io2)"
  type        = string
  default     = "gp3"
}

variable "additional_ebs_volumes" {
  description = "List of additional EBS volumes to attach"
  type = list(object({
    device_name = string
    volume_size = number
    volume_type = string
    encrypted   = bool
    kms_key_id  = string
  }))
  default = []
}

# IAM
variable "iam_instance_profile" {
  description = "IAM instance profile to attach to the EC2 instance"
  type        = string
  default     = null
}

# User Data
variable "user_data" {
  description = "User data script to execute on instance launch"
  type        = string
  default     = null
}

variable "user_data_base64" {
  description = "Base64 encoded user data"
  type        = string
  default     = null
}

# Monitoring and Maintenance
variable "enable_detailed_monitoring" {
  description = "Whether to enable detailed monitoring"
  type        = bool
  default     = false
}

variable "disable_api_termination" {
  description = "Whether to enable EC2 Instance Termination Protection"
  type        = bool
  default     = false
}

# Tags
variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Region
variable "region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}