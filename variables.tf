variable "bucket_name" {
  type        = string
  description = "Remote state bucket name"
  # 🟠 IMPORTANT: Terraform's backend "s3" block CANNOT reference input variables — it's evaluated before variables are loaded. So even though this variable exists and is set in terraform.tfvars, it CANNOT be used to set backend.tf's bucket name; that has to stay hardcoded there. This variable is likely dead/unused unless it's referenced somewhere else (e.g. an S3 bucket resource in a separate bootstrap config you haven't shown me). Flag this — may be safe to delete, or may belong to a bootstrap module.
}

variable "vpc_cidr" {
  type        = string
  description = "Public Subnet CIDR values"   # 🔴 CHANGE: copy-paste error in original — this describes vpc_cidr but says "Public Subnet CIDR values". Should say "VPC CIDR block"
}

variable "vpc_name" {
  type        = string
  description = "DevOps Project 1 VPC 1"      # 🔴 CHANGE: personalize, e.g. "VPC name for <your project>"
}

variable "cidr_public_subnet" {
  type        = list(string)
  description = "Public Subnet CIDR values"
}

variable "cidr_private_subnet" {
  type        = list(string)
  description = "Private Subnet CIDR values"
}

variable "eu_availability_zone" {
  type        = list(string)
  description = "Availability Zones"
  # 🔴 CHANGE (optional but recommended): rename this variable to something region-neutral like "availability_zones" if you're not deploying to eu-west-1 — "eu_availability_zone" is misleading otherwise. Must rename consistently in: main.tf, terraform.tfvars, and the networking module.
}

variable "public_key" {
  type        = string
  description = "DevOps Project 1 Public key for EC2 instance"   # 🔴 CHANGE: personalize project name in description
}

variable "ec2_ami_id" {
  type        = string
  description = "DevOps Project 1 AMI Id for EC2 instance"       # 🔴 CHANGE: personalize project name in description
}

#=================================================================
/*
Two real (non-cosmetic) things to flag:

None of these variables have default values. That's fine as long as you always supply terraform.tfvars (which you're already doing) — just confirming this is intentional, not a mistake, since some people expect defaults for convenience.
bucket_name is very likely dead code — Terraform backend blocks are parsed before variable resolution happens, so var.bucket_name structurally cannot wire into backend.tf's bucket. Unless you have a separate bootstrap .tf file (like an aws_s3_bucket resource) that consumes this variable to create the state bucket, this variable does nothing. Do you have such a bootstrap file? If not, I'd suggest removing this variable to avoid confusion — up to you.

Keep the files coming — networking module next would be great, since it's referenced by almost everything else and has the most renamed-output work (dev_proj_1_vpc_id, dev_proj_1_public_subnets, etc.).
*/
