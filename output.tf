output "jenkins_ec2_connection_string" {
  value = format(
    "%s%s",
    "ssh -i ~/.ssh/aws_ec2_terraform ubuntu@",   # 🔴 CHANGE: "/Users/rahulwagh/.ssh/..." is the original author's local machine path — replace with YOUR private key path (whatever you name/store the key you generate for Option A)
    module.jenkins.dev_proj_1_ec2_instance_public_ip  # 🔴 CHANGE: rename output "dev_proj_1_ec2_instance_public_ip" -> your naming, and it must match whatever the jenkins module actually outputs (need to see jenkins module's outputs.tf to confirm this name exists)
  )
}
