terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.2"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "4.7.1"
    }
    random = {
      source = "hashicorp/random"
      version = "3.5.1"
    }
  }
}

#
#  Generating Secrets for the Tunnel
# ==================================
  resource "random_password" "tunnel_secret" {
    length           = 32
    special          = false
  }

#
#  Setting up a Cloudflare Tunnel
# ===============================
  resource "cloudflare_tunnel" "terraformed_tunnel" {
    account_id = data.cloudflare_accounts.accounts.accounts[0].id
    name       = var.CF_tunnel_name
    secret     = random_password.tunnel_secret.result
  }

  resource "cloudflare_tunnel_config" "terraformed_tunnel_config" {
    account_id = data.cloudflare_accounts.accounts.accounts[0].id
    tunnel_id  = cloudflare_tunnel.terraformed_tunnel.id

    config {
      dynamic "ingress_rule" {
        for_each = var.SUBDOMAINS
        content {
          hostname = "${ingress_rule.value["subdomain"]}.${var.DOMAIN}"
          service  = ingress_rule.value["service"]
        }
      }
      ingress_rule {
        service = "http_status:404"
      }
    }

  }

#
#  Setting up DNS records with Cloudflare
# =======================================

  # # !!!   Use in case the domain doesn't exist

  # resource "cloudflare_zone" "domain" {
  #   zone = var.DOMAIN
  #   account_id = data.cloudflare_accounts.accounts.accounts[0].id

  #   lifecycle {
  #     prevent_destroy = true
  #   }
  # }

  # # !!!   Change:
  # # !!!     resource "cloudflare_record" "tunnel_cnames" {
  # # !!!       zone_id = data.cloudflare_zone.domain.id
  # # !!!   To:
  # # !!!     resource "cloudflare_record" "tunnel_cnames" {
  # # !!!       zone_id = cloudflare_zone.domain.id

  resource "cloudflare_record" "tunnel_cnames" {
    count = length(var.SUBDOMAINS)

    zone_id = data.cloudflare_zone.domain.id
    name    = var.SUBDOMAINS[count.index].subdomain
    type    = "CNAME"
    value   = "${cloudflare_tunnel.terraformed_tunnel.id}.cfargotunnel.com"
    proxied = true

    depends_on = [
      cloudflare_tunnel.terraformed_tunnel
    ]
  }


#
#  Setting up CloudflareD in Docker
# =================================

  resource "docker_network" "cloudflared_network" {
    name = "cloudflared_network"
  }
  resource "docker_volume" "cloudflared_storage" {
    name = "cloudflared_storage"
  }
  resource "docker_image" "cloudflared" {
    name = "cloudflare/cloudflared:latest"
  }

  resource "docker_container" "cloudflared_container" {
    name  = "cloudflared_tunnel"
    image = docker_image.cloudflared.image_id
    restart = "always"

    command = [
      "tunnel", "run", "--token", cloudflare_tunnel.terraformed_tunnel.tunnel_token
    ]

    networks_advanced {
      name = "cloudflared_network"
    }

    volumes {
      container_path = "/root/.cloudflared"
      volume_name    = "cloudflared_storage"
      read_only      = false
    }

    depends_on = [
      cloudflare_tunnel.terraformed_tunnel
    ]

  }