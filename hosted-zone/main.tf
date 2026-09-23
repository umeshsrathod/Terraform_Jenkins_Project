variable "domain_name" {}
variable "aws_lb_dns_name" {}
variable "aws_lb_zone_id" {}

data "aws_route53_zone" "dev_proj_1_jhooq_org" {   # 🔴 CHANGE (required): the resource label itself references "jhooq_org" — rename to match your domain for clarity, e.g. "primary_zone" or based on your domain. Not functionally required to rename, but confusing to leave as-is.
  name         = "jhooq.org"                        # 🔴 CHANGE — CRITICAL: this is HARDCODED to the original author's domain. Must change to YOUR root domain (e.g. if your Jenkins URL is jenkins.yourdomain.com, this should be "yourdomain.com" — the ROOT domain, not the subdomain)
  private_zone = false
}

resource "aws_route53_record" "lb_record" {
  zone_id = data.aws_route53_zone.dev_proj_1_jhooq_org.zone_id
  name    = var.domain_name                          # ✅ No change — comes from root main.tf, which you already fix by setting your domain there
  type    = "A"

  alias {
    name                   = var.aws_lb_dns_name
    zone_id                = var.aws_lb_zone_id
    evaluate_target_health = true
  }
}

output "hosted_zone_id" {
  value = data.aws_route53_zone.dev_proj_1_jhooq_org.zone_id
}

#==========================================================
/*
Two things worth flagging, one is critical:

1. CRITICAL — this uses data, not resource, for the Route53 zone. That means Terraform expects the hosted zone (jhooq.org in the original) to already exist in Route53 before you run apply — this module does not create a hosted zone, it only looks one up and adds an A record (alias) to it.

So for your setup, you need to confirm:

Is your domain's DNS already delegated to Route53 (i.e. does a hosted zone for your root domain already exist in your AWS account)? If yes → just change name = "jhooq.org" to your root domain and you're done.
If you registered your domain elsewhere (GoDaddy, Namecheap, etc.) and haven't set up Route53 as the DNS provider yet, you have two choices:
(a) Create a Route53 hosted zone for your domain, then update your domain registrar's nameservers to point to Route53's — this can take time to propagate (up to 48h sometimes).
(b) Skip Route53 entirely and manually create an equivalent A/CNAME record at your current DNS provider pointing to the ALB's DNS name (you'd lose the "alias" auto-integration but it still works).

Which situation are you in — is your domain already on Route53, or elsewhere?

2. Variable naming consistency — this module's domain_name variable expects the full subdomain (jenkins.yourdomain.com), while the data source's hardcoded name expects the root domain (yourdomain.com). Easy to mix these up when you edit — just keep that distinction in mind:

data "aws_route53_zone" name → root domain only
var.domain_name (fed from root main.tf) → full subdomain for Jenkins

Send networking next when ready — it's the biggest one and touches nearly every other module's vpc_id/subnet references.
*/
