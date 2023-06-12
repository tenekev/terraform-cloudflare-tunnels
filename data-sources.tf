data "cloudflare_accounts" "accounts" {}

data "cloudflare_zone" "domain" {
  name       = var.DOMAIN
  account_id = data.cloudflare_accounts.accounts.accounts[0].id
}