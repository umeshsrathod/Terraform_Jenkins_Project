provider "aws" {
  region                   = "eu-west-1"                                  # 🔴 CHANGE: pick the region YOU want to deploy in (e.g. "us-east-1", "ap-south-1" for Mumbai since you're near Pune, etc.) — this also affects the "eu_availability_zone" var in main.tf/networking module, which needs to match whatever region you choose here
  shared_credentials_files = ["/Users/rahulwagh/.aws/credentials"]        # 🔴 CHANGE: this is the original author's Mac username/path — almost certainly wrong for you. See options below.
}

#==========================================================================================================
/*
Two things to fix here:

1. Region — eu-west-1 (Ireland) only makes sense if you actually want to deploy there (e.g. GDPR/EU-data reasons, or your users are EU-based). If you're in India, ap-south-1 (Mumbai) will give lower latency. Whatever you pick, remember: the networking module has a variable literally called eu_availability_zone — if you change region away from eu-west-1, you should also rename that variable (it's misleading otherwise) and update its AZ values (e.g. ap-south-1a, ap-south-1b instead of eu-west-1a, eu-west-1b).

2. shared_credentials_files — hardcoded to the original dev's personal Mac path. You have a few options, best practice first:

Best: Remove this line entirely. If you run aws configure locally (which creates ~/.aws/credentials in the default OS location), Terraform's AWS provider finds it automatically — no path needed. Simplest and portable across machines/OSes.
If you must pin a custom path: replace with your actual path, e.g. Linux/WSL: ["/home/youruser/.aws/credentials"], Windows: ["C:/Users/youruser/.aws/credentials"].
For CI/CD (e.g. this deploying from GitHub Actions, Jenkins itself, etc.): don't use credentials files at all — use environment variables (AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY) or better, an IAM role via OIDC. Let me know if this is your setup, it changes this file more.
*/
