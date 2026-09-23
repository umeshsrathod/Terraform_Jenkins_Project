variable "lb_target_group_name" {}
variable "lb_target_group_port" {}
variable "lb_target_group_protocol" {}
variable "vpc_id" {}
variable "ec2_instance_id" {}

output "dev_proj_1_lb_target_group_arn" {                    # 🔴 CHANGE: rename output, e.g. "lb_target_group_arn" — update root main.tf reference (module.lb_target_group.dev_proj_1_lb_target_group_arn) to match
  value = aws_lb_target_group.dev_proj_1_lb_target_group.arn
}

resource "aws_lb_target_group" "dev_proj_1_lb_target_group" {   # 🔴 CHANGE (optional): rename resource label, e.g. "jenkins_tg" — only affects references within this file (3 places)
  name     = var.lb_target_group_name
  port     = var.lb_target_group_port
  protocol = var.lb_target_group_protocol
  vpc_id   = var.vpc_id
  health_check {
    path                = "/login"      # ✅ Jenkins-specific and correct — Jenkins' login page returns 200, good health check target. Keep as-is unless you disable Jenkins login/security, in which case use "/" instead.
    port                = 8080          # 🐛 HARDCODED — should be var.lb_target_group_port instead of a literal 8080, so it doesn't silently diverge if you ever change the port variable. Low risk today since both happen to be 8080, but worth fixing for consistency.
    healthy_threshold   = 6             # 🟡 OK — takes 6 consecutive passes to mark healthy (with 5s interval = ~30s). Fine for Jenkins' slower boot, can tune later.
    unhealthy_threshold = 2
    timeout             = 2
    interval            = 5
    matcher             = "200"
  }
}

resource "aws_lb_target_group_attachment" "dev_proj_1_lb_target_group_attachment" {   # 🔴 CHANGE (optional): rename resource label to match your convention
  target_group_arn = aws_lb_target_group.dev_proj_1_lb_target_group.arn
  target_id        = var.ec2_instance_id
  port              = 8080   # 🐛 SAME ISSUE — hardcoded again instead of var.lb_target_group_port. Root main.tf even defines a separate var lb_target_group_attachment_port = 8080 for the ALB module, but THIS module never receives or uses that variable — it's just hardcoded here instead. Inconsistent design in the original script.
}

#================================================================

/*
Two real (not cosmetic) issues:

Port hardcoded twice (health check port and attachment port) instead of using var.lb_target_group_port. Both happen to equal 8080 today, so it works — but if you ever change the Jenkins port, you'd have to remember to update these two literals separately from the variable, which is a classic source of drift bugs. Recommend:

health_check {
  path = "/login"
  port = var.lb_target_group_port
  ...
}
...
resource "aws_lb_target_group_attachment" "..." {
  ...
  port = var.lb_target_group_port
}

lb_target_group_attachment_port variable in main.tf's alb module is a dead/misleading variable — I noticed earlier in root main.tf there's lb_target_group_attachment_port = 8080 passed to the alb module, but this target-group module (where the actual attachment resource lives) never receives that variable at all. Worth checking the load-balancer module file (haven't seen it yet) — if that variable also isn't used there, it may be entirely orphaned. I'll confirm once you send that file.

Send networking, security-groups, or load-balancer next — any of those keeps us moving toward a complete picture.
*/
