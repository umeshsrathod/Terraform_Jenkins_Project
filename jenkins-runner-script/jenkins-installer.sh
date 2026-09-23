#!/bin/bash
sudo apt-get update
yes | sudo apt install openjdk-11-jdk-headless
# 🟠 REVIEW: Java 11 is old for modern Jenkins — current Jenkins (2.46x+) requires Java 17 or 21, and will refuse to start on Java 11. Depending on which Jenkins version apt installs today, this line may silently break. Recommend changing to openjdk-17-jdk-headless (safer, widely supported) unless you have a reason to pin Java 11.

echo "Waiting for 30 seconds before installing the jenkins package..."
sleep 30   # 🟡 Fragile — a fixed sleep isn't a real readiness check, but low-risk to leave as-is for now

sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
  # 🔴 CHANGE: this key URL is dated "2023" and may be rotated/outdated by the time you run this. Check Jenkins' official install docs (pkg.jenkins.io) for the current key URL before using — I can verify the current one live if you want.

echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update
yes | sudo apt-get install jenkins
sleep 30
echo "Waiting for 30 seconds before installing the Terraform..."
wget https://releases.hashicorp.com/terraform/1.6.5/terraform_1.6.5_linux_386.zip
# 🔴 CHANGE (2 issues):
#   1. Version 1.6.5 is old (current stable is much newer as of 2026) — pin to a recent version, e.g. check latest at releases.hashicorp.com/terraform
#   2. "linux_386" is 32-BIT architecture — almost certainly wrong. Your EC2 instance (t2.medium/t3.medium) is 64-bit x86, so this should be "linux_amd64". Installing a 32-bit binary on a 64-bit instance may fail outright or behave unpredictably. This looks like a bug in the original script.

yes | sudo apt-get install unzip
unzip 'terraform*.zip'
sudo mv terraform /usr/local/bin/

#===================================================================================================
/*
Real issues here (not just cosmetic renaming — these can break your deploy):

linux_386 is very likely a bug. Your t2.medium instance is 64-bit. This should almost certainly be linux_amd64. I'd fix this regardless of what else you change.
Java 11 + modern Jenkins is a real compatibility risk. If apt-get install jenkins pulls the latest Jenkins today, it may need Java 17/21 and fail to start, or start broken. Recommend bumping to openjdk-17-jdk-headless.
Terraform 1.6.5 is stale. Not broken, but you'd be installing an old version on the Jenkins box unnecessarily — worth pinning to something current.
No error handling — if any wget/apt step fails, the script just continues. Not critical for a first working version, but worth knowing: if Jenkins doesn't come up, check /var/log/jenkins/jenkins.log on the instance and also check cloud-init output (/var/log/cloud-init-output.log) to see where user_data failed.

Want me to rewrite this script fully fixed (amd64 + Java 17 + latest Terraform + basic error checks), or do you want to test/adjust incrementally yourself first? Also — still need the networking, jenkins, security-groups, load-balancer, and load-balancer-target-group module files whenever you're ready to keep going.
*/
