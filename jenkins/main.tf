variable "ami_id" {}
variable "instance_type" {}
variable "tag_name" {}
variable "public_key" {}
variable "subnet_id" {}
variable "sg_for_jenkins" {}
variable "enable_public_ip_address" {}
variable "user_data_install_jenkins" {}

output "ssh_connection_string_for_ec2" {
  value = format("%s%s", "ssh -i /Users/rahulwagh/.ssh/aws_ec2_terraform ubuntu@", aws_instance.jenkins_ec2_instance_ip.public_ip)
  # 🔴 CHANGE: same hardcoded personal path issue as before — "/Users/rahulwagh/.ssh/aws_ec2_terraform" needs to become YOUR key path
}

output "jenkins_ec2_instance_ip" {                              # 🐛 BUG — name is WRONG, not just cosmetic
  value = aws_instance.jenkins_ec2_instance_ip.id                # this returns the INSTANCE ID, not an IP address. The output name "jenkins_ec2_instance_ip" is misleading.
  # 🔴 CHANGE: rename to "jenkins_ec2_instance_id" for clarity. IMPORTANT: root main.tf references module.jenkins.jenkins_ec2_instance_ip in TWO places (lb_target_group's ec2_instance_id, and alb's ec2_instance_id) — it "works" only because those modules actually need an instance ID there, and this output happens to (confusingly) return one despite its name. If you rename this output, update both call sites in main.tf too.
}

output "dev_proj_1_ec2_instance_public_ip" {
  value = aws_instance.jenkins_ec2_instance_ip.public_ip          # ✅ this one is correctly named-to-value (returns actual public IP)
  # 🔴 CHANGE: rename prefix to drop "dev_proj_1", e.g. "jenkins_ec2_public_ip" — and update the reference in your root outputs.tf (the connection-string output we marked up earlier)
}

resource "aws_instance" "jenkins_ec2_instance_ip" {                # 🔴 CHANGE (optional): resource label "jenkins_ec2_instance_ip" is also misleadingly named (it's the instance, not an IP) — rename to e.g. "jenkins_server" for clarity. If you rename, update every aws_instance.jenkins_ec2_instance_ip reference in this file (4 places).
  ami           = var.ami_id
  instance_type = var.instance_type
  tags = {
    Name = var.tag_name
  }
  key_name                    = "aws_ec2_terraform"                # 🐛 REVIEW: hardcoded string that happens to match aws_key_pair's key_name below — but it's not an actual Terraform reference. This means Terraform doesn't know this instance DEPENDS on the key pair existing first. Usually works by luck (key pair is fast to create), but the correct/safe way is to reference it directly — see suggestion below.
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.sg_for_jenkins
  associate_public_ip_address = var.enable_public_ip_address

  user_data = var.user_data_install_jenkins

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
}

resource "aws_key_pair" "jenkins_ec2_instance_public_key" {
  key_name   = "aws_ec2_terraform"    # 🔴 CHANGE: personalize, e.g. "${var.tag_name}-key" or just a fixed string like "myproj-jenkins-key". Must stay consistent with key_name above if you don't fix the reference bug.
  public_key = var.public_key
}

#=============================================================================

/*
Fix I'd recommend for the fragile key_name reference — instead of two hardcoded matching strings, reference the resource directly so Terraform enforces correct ordering:
resource "aws_instance" "jenkins_server" {
  ...
  key_name = aws_key_pair.jenkins_ec2_instance_public_key.key_name   # ✅ proper dependency
  ...
}

Also missing: root volume size. No root_block_device block — you'll get whatever the AMI's default disk size is (often just 8GB), which fills up fast with Jenkins + Terraform + build artifacts. Worth adding:

root_block_device {
  volume_size = 20   # GB, adjust to taste
  volume_type = "gp3"
}

Two summary bugs worth fixing when we finalize: the misleading jenkins_ec2_instance_ip output name (returns an ID, not an IP), and the non-enforced key-pair dependency. Neither breaks a first apply, but both will bite you eventually.

Send networking and security-groups next — those are the two biggest remaining pieces and I'll be able to check the subnet_id/vpc_id/SG wiring end-to-end once I have them.
*/
