variable "vpc_cidr" {}
variable "vpc_name" {}
variable "cidr_public_subnet" {}
variable "eu_availability_zone" {}   # 🔴 CHANGE (per earlier note): rename to "availability_zones" if not deploying to eu-west
variable "cidr_private_subnet" {}

output "dev_proj_1_vpc_id" {                                  # 🔴 CHANGE: rename, e.g. "vpc_id" — used in main.tf (security_group, lb_target_group modules) and needs matching update in both places
  value = aws_vpc.dev_proj_1_vpc_eu_central_1.id
}

output "dev_proj_1_public_subnets" {                          # 🔴 CHANGE: rename, e.g. "public_subnet_ids" — used in main.tf (jenkins, alb modules)
  value = aws_subnet.dev_proj_1_public_subnets.*.id
}

output "public_subnet_cidr_block" {                           # ✅ fine as-is, already clean naming, not currently used elsewhere but harmless to keep
  value = aws_subnet.dev_proj_1_public_subnets.*.cidr_block
}

resource "aws_vpc" "dev_proj_1_vpc_eu_central_1" {             # 🐛 NAMING BUG: resource label says "eu_central_1" but provider.tf/backend.tf region is "eu-west-1" — these don't match. Purely cosmetic (labels are just internal identifiers, not enforced against actual region), but clearly a copy-paste leftover from a different project. 🔴 CHANGE: rename to something accurate/generic, e.g. "main_vpc" — if you rename, update every aws_vpc.dev_proj_1_vpc_eu_central_1 reference in this file (7 places)
  cidr_block = var.vpc_cidr
  tags = {
    Name = var.vpc_name
  }
}

resource "aws_subnet" "dev_proj_1_public_subnets" {
  count             = length(var.cidr_public_subnet)
  vpc_id            = aws_vpc.dev_proj_1_vpc_eu_central_1.id
  cidr_block        = element(var.cidr_public_subnet, count.index)
  availability_zone = element(var.eu_availability_zone, count.index)

  tags = {
    Name = "dev-proj-public-subnet-${count.index + 1}"          # 🔴 CHANGE: personalize prefix, e.g. "myproj-public-subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "dev_proj_1_private_subnets" {
  count             = length(var.cidr_private_subnet)
  vpc_id            = aws_vpc.dev_proj_1_vpc_eu_central_1.id
  cidr_block        = element(var.cidr_private_subnet, count.index)
  availability_zone = element(var.eu_availability_zone, count.index)

  tags = {
    Name = "dev-proj-private-subnet-${count.index + 1}"         # 🔴 CHANGE: personalize prefix
  }
}

resource "aws_internet_gateway" "dev_proj_1_public_internet_gateway" {
  vpc_id = aws_vpc.dev_proj_1_vpc_eu_central_1.id
  tags = {
    Name = "dev-proj-1-igw"                                     # 🔴 CHANGE: personalize
  }
}

resource "aws_route_table" "dev_proj_1_public_route_table" {
  vpc_id = aws_vpc.dev_proj_1_vpc_eu_central_1.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dev_proj_1_public_internet_gateway.id
  }
  tags = {
    Name = "dev-proj-1-public-rt"                                # 🔴 CHANGE: personalize
  }
}

resource "aws_route_table_association" "dev_proj_1_public_rt_subnet_association" {
  count          = length(aws_subnet.dev_proj_1_public_subnets)
  subnet_id      = aws_subnet.dev_proj_1_public_subnets[count.index].id
  route_table_id = aws_route_table.dev_proj_1_public_route_table.id
}

resource "aws_route_table" "dev_proj_1_private_subnets" {
  vpc_id = aws_vpc.dev_proj_1_vpc_eu_central_1.id
  tags = {
    Name = "dev-proj-1-private-rt"                                # 🔴 CHANGE: personalize
  }
}

resource "aws_route_table_association" "dev_proj_1_private_rt_subnet_association" {
  count          = length(aws_subnet.dev_proj_1_private_subnets)
  subnet_id      = aws_subnet.dev_proj_1_private_subnets[count.index].id
  route_table_id = aws_route_table.dev_proj_1_private_subnets.id
}

#========================================================================================================
/*
Structurally this module is actually solid (VPC, public/private subnets, IGW, route tables, associations — all correctly wired). Mostly renaming work here, but two real design points to be aware of:

Private subnets exist but have no outbound internet route — the private route table has no NAT Gateway attached (#depends_on = [aws_nat_gateway.nat_gateway] was commented out, and there's no aws_nat_gateway resource anywhere in this file). That's fine for your current setup, since Jenkins runs in the public subnet and nothing currently uses the private subnets at all. But it means: if you later add anything to the private subnets (a database, an internal agent, etc.), it will have no internet access (can't apt update, pull Docker images, etc.) until you add a NAT Gateway (~$32/month + data charges) or a NAT instance. Not something to fix now — just flagging it so it doesn't surprise you later.
No output for private subnet IDs — consistent with point 1 (nothing uses them yet), but if you extend this later you'll want to add output "private_subnet_ids" { value = aws_subnet.dev_proj_1_private_subnets.*.id }.

Last file to go: security-groups module. Once I see that, I'll have everything and can give you the full consolidated rename checklist across all files in one shot.
*/
