variable "CF_email" {
  description = ""
  type = string
}

variable "CF_apikey" {
  description = "Available at https://dash.cloudflare.com/profile/api-tokens"
  type = string
}

variable "CF_apitoken" {
  description = "Available at https://dash.cloudflare.com/profile/api-tokens"
  type = string
}

variable "CF_tunnel_name" {
  description = ""
  type = string
  default = "terraformed_tunnel"
}

variable "DOMAIN" {
  description = "The domain that will be managed"
  type = string
}

variable "SUBDOMAINS" {
  description = "The map of services and subdomains they will be accessible at."
  type = list(object({
    subdomain  = string
    service    = string
  }))
  default = []
}