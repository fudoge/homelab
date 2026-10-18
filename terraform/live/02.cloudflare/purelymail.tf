resource "cloudflare_dns_record" "purelymail_ownership_record" {
  zone_id = var.zone_id
  name    = "@"
  ttl     = 1
  type    = "TXT"
  proxied = false
  comment = "PurelyMail Ownership record"
  content = var.purelymail_ownership_record_value
}

resource "cloudflare_dns_record" "purelymail_mx_record" {
  zone_id  = var.zone_id
  name     = "@"
  ttl      = 1
  type     = "MX"
  proxied  = false
  priority = 50
  comment  = "PurelyMail MX record"
  content  = "mailserver.purelymail.com."
}

resource "cloudflare_dns_record" "purelymail_spf_record" {
  zone_id = var.zone_id
  name    = "@"
  ttl     = 1
  type    = "TXT"
  proxied = false
  comment = "PurelyMail SPF record"
  content = "\"v=spf1 include:_spf.purelymail.com ~all\""
}

resource "cloudflare_dns_record" "purelymail_dkim_record" {
  count = 3

  zone_id = var.zone_id
  name    = "purelymail${count.index + 1}._domainkey"
  ttl     = 1
  type    = "CNAME"
  proxied = false
  comment = "PurelyMail DKIM record - ${count.index + 1}"
  content = "key${count.index + 1}.dkimroot.purelymail.com."
}

resource "cloudflare_dns_record" "purelymail_dmarc_record" {
  zone_id = var.zone_id
  name    = "_dmarc"
  ttl     = 1
  type    = "CNAME"
  proxied = false
  comment = "PurelyMail DMARC record"
  content = "dmarcroot.purelymail.com."
}

resource "cloudflare_dns_record" "purelymail_autoconfig_record" {
  zone_id = var.zone_id
  name    = "autoconfig"
  ttl     = 1
  type    = "CNAME"
  proxied = false
  comment = "PurelyMail autoconfig record"
  content = "autoconfig.purelymail.com."
}

resource "cloudflare_dns_record" "purelymail_autodiscover_record" {
  zone_id = var.zone_id
  name    = "_autodiscover._tcp"
  ttl     = 1
  type    = "SRV"
  proxied = false
  comment = "Purelymail autodiscover record"
  data = {
    priority = 0
    weight   = 0
    port     = 443
    target   = "autodiscover.purelymail.com."
  }
}
