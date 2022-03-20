module "shared_infrastructure" {
  source      = "git::ssh://git@github.com/vendorcorp/terraform-shared-infrastructure.git?ref=v0.2.1"
  environment = var.environment
}

resource "aws_directory_service_directory" "vendorcorp_ldap" {
  name        = "corp.vendorcorp.net"
  short_name  = "corp"
  description = "Shared LDAP service for Vendor Corp"
  password    = local.ldap_admin_password
  edition     = "Standard"
  type        = "MicrosoftAD"

  vpc_settings {
    vpc_id = module.shared_infrastructure.vpc_id
    # Items in a Set cannot be accessed by index - convert to a List first: https://www.terraform.io/language/functions/tolist
    subnet_ids = [tolist(module.shared_infrastructure.private_subnet_ids)[0], tolist(module.shared_infrastructure.private_subnet_ids)[1]]
  }

  tags = var.default_resource_tags
}

resource "aws_route53_record" "dns_ldap_vendorcorp_internal" {
  zone_id = module.shared_infrastructure.dns_zone_internal_id
  name    = "ldap.vendorcorp.internal"
  type    = "A"
  ttl     = "300"
  records = aws_directory_service_directory.vendorcorp_ldap.dns_ip_addresses
}

resource "aws_route53_record" "dns_ldap_vendorcorp_public" {
  zone_id = module.shared_infrastructure.dns_zone_public_id
  name    = "ldap.corp.vendorcorp.net"
  type    = "A"
  ttl     = "300"
  records = aws_directory_service_directory.vendorcorp_ldap.dns_ip_addresses
}

data "aws_eks_node_groups" "example" {
  cluster_name = module.shared_infrastructure.eks_cluster_id
}

data "aws_launch_template" "templates" {
  for_each = data.aws_eks_node_groups.example.names
  tags = {
    "eks:cluster-name" = module.shared_infrastructure.eks_cluster_id
  }
  filter {
    name   = "tag:eks:nodegroup-name"
    values = [each.value]
  }
}

locals {
  vpc_security_group_ids = distinct(flatten([
    for template_name in keys(data.aws_launch_template.templates) : [
      data.aws_launch_template.templates[template_name].vpc_security_group_ids
    ]
  ]))
}

resource "aws_security_group_rule" "allow_ldap" {
  count                    = length(local.vpc_security_group_ids)
  type                     = "egress"
  from_port                = 389
  to_port                  = 389
  protocol                 = "tcp"
  security_group_id        = local.vpc_security_group_ids[count.index]
  source_security_group_id = aws_directory_service_directory.vendorcorp_ldap.security_group_id
}

resource "aws_security_group_rule" "allow_ldaps" {
  count                    = length(local.vpc_security_group_ids)
  type                     = "egress"
  from_port                = 636
  to_port                  = 636
  protocol                 = "tcp"
  security_group_id        = local.vpc_security_group_ids[count.index]
  source_security_group_id = aws_directory_service_directory.vendorcorp_ldap.security_group_id
}
