module "shared_infrastructure" {
  source      = "git::ssh://git@github.com/vendorcorp/terraform-shared-infrastructure.git?ref=v0.1.0"
  environment = var.environment
}

resource "aws_directory_service_directory" "vendorcorp_ldap" {
  name        = "vendorcorp.internal"
  short_name  = "vendorcorp"
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

resource "aws_route53_record" "dns_ldap_vendorcorp_intenral" {
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
