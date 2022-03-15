module "shared_infrastructure" {
  source      = "git::ssh://git@github.com/vendorcorp/terraform-shared-infrastructure.git?ref=v0.0.3"
  environment = var.environment
}

provider "helm" {
  kubernetes {
    config_path    = "~/.kube/config"
    config_context = module.shared_infrastructure.eks_cluster_arn
  }
}

resource "random_string" "password_admin" {
  length  = 20
  special = true
}

resource "random_string" "password_config" {
  length  = 20
  special = true
}

resource "helm_release" "shared_openldap" {
  name = "ldap"
  # repository = "https://jp-gouin.github.io/helm-openldap/"
  # chart      = "helm-openldap/openldap-stack-ha"
  # version    = "2.1.6"
  chart            = "https://github.com/jp-gouin/helm-openldap/archive/refs/tags/v2.1.6.tar.gz"
  create_namespace = true
  namespace        = "shared-core"

  values = [
    "${file("values.yaml")}"
  ]

  # set {
  #   name  = "extraLabels"
  #   value = var.default_resource_tags
  # }

  # set {
  #   name  = "env.LDAP_DOMAIN"
  #   value = module.shared_infrastructure.dns_zone_internal_name
  # }

  set_sensitive {
    name  = "adminPassword"
    value = random_string.password_admin.result
  }

  set_sensitive {
    name  = "configPassword"
    value = random_string.password_config.result
  }

  # set {
  #   name  = "replication.clusterName"
  #   value = "ldap.${module.shared_infrastructure.dns_zone_internal_name}"
  # }

  # set {
  #   name  = "phpldapadmin.env.PHPLDAPADMIN_LDAP_HOSTS"
  #   value = "shared-core.ldap"
  # }

  # set {
  #   name  = "phpldapadmin.ingress.hosts"
  #   value = "{ldapadmin.${module.shared_infrastructure.dns_zone_internal_name}}"
  # }

  # set {
  #   name  = "ltb-passwd.ldap.server"
  #   value = "ldap://shared-core.ldap"
  # }

  # set {
  #   name  = "ltd-passwd.ldap.searchBase"
  #   value = "dc=vendorcorop,dc=internal"
  # }

  # set {
  #   name  = "ltb-passwd.ldap.bindDN"
  #   value = "cn=admin,dc=vendorcorop,dc=internal"
  # }

  # set {
  #   name  = "service.annotations.prometheus\\.io/port"
  #   value = "9127"
  #   type  = "string"
  # }
}
