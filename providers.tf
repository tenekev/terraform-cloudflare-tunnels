provider "docker" {}

provider "cloudflare" {
  # Either
    #email  = var.CF_email
    #api_key = var.CF_apikey
  # or
    api_token = var.CF_apitoken
}