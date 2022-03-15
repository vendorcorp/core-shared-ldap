output "ldap_admin_password" {
  value = random_string.password_admin.result
}

output "ldap_config_password" {
  value = random_string.password_config.result
}
