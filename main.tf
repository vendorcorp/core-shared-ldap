module "shared_infrastructure" {
  source      = "git::ssh://git@github.com/sonatype/terraform-shared-infrastructure.git?ref=v0.0.4"
  environment = var.environment
}

resource "aws_directory_service_directory" "vendorcorp_ldap" {
  name        = "ldap.vendorcorp.internal"
  short_name  = "ldap"
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
