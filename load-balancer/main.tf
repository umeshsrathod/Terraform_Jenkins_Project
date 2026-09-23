variable "lb_name" {}
variable "lb_type" {}
variable "is_external" { default = false }
variable "sg_enable_ssh_https" {}
variable "subnet_ids" {}
variable "tag_name" {}
variable "lb_target_group_arn" {}
variable "ec2_instance_id" {}                     # 🔴 DELETE (after removing duplicate attachment resource below)
variable "lb_listner_port" {}
variable "lb_listner_protocol" {}
variable "lb_listner_default_action" {}
variable "lb_https_listner_port" {}
variable "lb_https_listner_protocol" {}
variable "dev_proj_1_acm_arn" {}                  # 🔴 CHANGE: rename to "acm_arn" or similar, matching the certificate-manager module output rename
variable "lb_target_group_attachment_port" {}     # 🔴 DELETE (after removing duplicate attachment resource below)

output "aws_lb_dns_name" {
  value = aws_lb.dev_proj_1_lb.dns_name           # ✅ fine as-is, output name is already clean (no dev_proj_1 prefix)
}

output "aws_lb_zone_id" {
  value = aws_lb.dev_proj_1_lb.zone_id            # ✅ fine as-is
}

resource "aws_lb" "dev_proj_1_lb" {                # 🔴 CHANGE (optional): rename label, e.g. "jenkins_alb"
  name               = var.lb_name
  internal           = var.is_external
  # 🐛 CONFUSING VARIABLE NAME: "internal" is being set from a variable literally called "is_external" — with is_external=false (as passed in root main.tf), internal becomes false, which correctly makes this an internet-facing (external) ALB. The LOGIC works, but the NAME is backwards/confusing: is_external=false → actually IS external-facing. Recommend renaming variable to "is_internal" (matching what it actually controls) and flipping the value passed in main.tf accordingly (is_internal = false), OR keep the name but document clearly. Your call — just don't let the naming confuse you when you edit it later.
  load_balancer_type = var.lb_type
  security_groups    = [var.sg_enable_ssh_https]
  subnets            = var.subnet_ids

  enable_deletion_protection = false               # 🟡 REVIEW: fine for dev/testing. For anything you care about not accidentally destroying, consider true in production.

  tags = {
    Name = "example-lb"                            # 🔴 CHANGE: hardcoded — should be var.tag_name (which is already passed in from main.tf as "dev-proj-1-alb" but never actually used here!). Change to: Name = var.tag_name
  }
}

resource "aws_lb_target_group_attachment" "dev_proj_1_lb_target_group_attachment" {  # 🔴 DELETE THIS ENTIRE RESOURCE — duplicate of the one in load-balancer-target-group module (see critical bug above)
  target_group_arn = var.lb_target_group_arn
  target_id        = var.ec2_instance_id
  port             = var.lb_target_group_attachment_port
}

resource "aws_lb_listener" "dev_proj_1_lb_listner" {   # 🔴 CHANGE (optional): rename label + fix typo "listner" -> "listener" throughout file if you want clean naming
  load_balancer_arn = aws_lb.dev_proj_1_lb.arn
  port              = var.lb_listner_port
  protocol          = var.lb_listner_protocol

  default_action {
    type             = var.lb_listner_default_action
    target_group_arn = var.lb_target_group_arn
  }
  # 🟡 NOTE: this HTTP (port 80) listener currently just forwards straight to the target group (plaintext). Since you're adding HTTPS below, consider changing this listener's default_action to a redirect to HTTPS instead of forwarding, so all traffic ends up encrypted:
  # default_action {
  #   type = "redirect"
  #   redirect {
  #     port        = "443"
  #     protocol    = "HTTPS"
  #     status_code = "HTTP_301"
  #   }
  # }
  # (If you do this, lb_listner_default_action var becomes unused for this listener but still used for the HTTPS one below.)
}

resource "aws_lb_listener" "dev_proj_1_lb_https_listner" {
  load_balancer_arn = aws_lb.dev_proj_1_lb.arn
  port              = var.lb_https_listner_port
  protocol          = var.lb_https_listner_protocol
  ssl_policy        = "ELBSecurityPolicy-FS-1-2-Res-2019-08"   # ✅ fine, modern TLS policy
  certificate_arn   = var.dev_proj_1_acm_arn                    # 🔴 CHANGE: rename var per above; also — if you add the aws_acm_certificate_validation resource I suggested earlier, point this at that resource's .certificate_arn instead, for safer sequencing

  default_action {
    type             = var.lb_listner_default_action
    target_group_arn = var.lb_target_group_arn
  }
}

#===============================================================
/*

Summary of real fixes needed here (not cosmetic):

Delete the duplicate aws_lb_target_group_attachment in this file — keep the one in load-balancer-target-group module. Remove the now-unused ec2_instance_id and lb_target_group_attachment_port variables here, and stop passing them from root main.tf's alb module block.
tags.Name = "example-lb" is hardcoded and ignores the tag_name variable that's already being passed in — fix to var.tag_name.
Confusing is_external/internal naming — works correctly today but rename if you want it to make sense on a second read.
Optional: HTTP→HTTPS redirect instead of HTTP forwarding, for a real production setup.

Still need: networking and security-groups modules — those are the last two, and once I see them I'll give you the complete consolidated list of every rename needed across the whole project so you can do a clean find-and-replace pass.
CRITICAL bug found — duplicate target group attachment. This module creates aws_lb_target_group_attachment.dev_proj_1_lb_target_group_attachment, attaching your EC2 instance to the target group. But the load-balancer-target-group module we reviewed earlier already creates its own aws_lb_target_group_attachment resource, attaching the exact same instance to the exact same target group. Two separate Terraform resources both trying to register the same EC2 instance+port against the same target group ARN will either error on apply (AWS rejects duplicate registration) or cause a confusing permanent diff where Terraform keeps fighting itself on every plan.

Fix: delete one of them. I'd remove this one (in load-balancer module) and keep the one in load-balancer-target-group, since that module conceptually owns the target group's attachments — more logical separation. That also means lb_target_group_attachment_port and ec2_instance_id variables can be deleted from this module entirely (dead weight once the duplicate resource is gone).
*/
