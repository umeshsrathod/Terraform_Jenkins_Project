variable "domain_name" {}
variable "hosted_zone_id" {}

output "dev_proj_1_acm_arn" {                              # 🔴 CHANGE: rename to your convention, e.g. "acm_certificate_arn" — must update the reference in root main.tf (dev_proj_1_acm_arn -> new name)
  value = aws_acm_certificate.dev_proj_1_acm_arn.arn
}

resource "aws_acm_certificate" "dev_proj_1_acm_arn" {       # 🔴 CHANGE (optional): rename resource label, e.g. "jenkins_cert" — purely internal, no other file references the label directly, only the output above does
  domain_name       = var.domain_name                        # ✅ No change needed here — this pulls from module call in main.tf, which YOU already fix by setting your domain there
  validation_method = "DNS"

  tags = {
    Environment = "production"                                # 🔴 CHANGE: hardcoded — should probably be var.environment or match your actual env (dev/staging/prod), not always "production"
  }

  lifecycle {
    create_before_destroy = false   # 🟠 REVIEW: for ACM certs, this is usually recommended as `true` — with false, if you ever need to replace this cert (e.g. domain change), Terraform destroys the old one before creating the new one, which can cause a brief HTTPS outage on your ALB listener since the listener references this cert's ARN. Recommend changing to true unless you have a reason not to.
  }
}

resource "aws_route53_record" "validation" {
  for_each = {
    for dvo in aws_acm_certificate.dev_proj_1_acm_arn.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = var.hosted_zone_id   # comment "replace with your Hosted Zone ID" is misleading — 🟢 this is already dynamic via var.hosted_zone_id, fed from module.hosted_zone.hosted_zone_id in root main.tf. Nothing to hardcode here. You can delete that stale comment.
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}

#==============================================================================

/*
Notable things:

Missing: certificate validation wait. This module creates the cert and the DNS validation records, but there's no aws_acm_certificate_validation resource waiting for AWS to actually confirm validation before other resources (like the ALB HTTPS listener) try to use the cert ARN. In practice this often works anyway because of how Terraform sequences dependencies, but it's fragile — first apply can sometimes fail because the cert isn't validated yet, and a second apply succeeds. I'd recommend adding:

resource "aws_acm_certificate_validation" "this" {
  certificate_arn         = aws_acm_certificate.dev_proj_1_acm_arn.arn
  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]
}
And optionally point the ALB's dev_proj_1_acm_arn output/reference at aws_acm_certificate_validation.this.certificate_arn instead of the raw cert resource, so Terraform waits properly. Want me to add this when we finalize?

Environment = "production" tag — worth making dynamic (var.environment) once you know your naming convention, so it's not misleadingly hardcoded if this is actually your dev/staging environment.

Send the hosted-zone module next (it pairs directly with this one), or the networking module — whichever you have handy.

*/
