provider "huaweicloud" {
  region      = var.region
  access_key  = var.ak
  secret_key  = var.sk
  auth_url    = "https://iam.${var.region}.myhuaweicloud.com/v3"
}
#waf creation in post paid and cloud mode
resource "huaweicloud_waf_cloud_instance" "myWAF" {
  charging_mode = "postPaid"
  website = "hec-hk"
}
#no funca
#agregar el dominio al waf
resource "huaweicloud_waf_domain" "addPhoebeToWAF" {
  domain                = "phoebe.cl"
  description           = "adding phoebe to waf"
  website_name          = "dvwa"
  server {
    client_protocol = "HTTP"
    server_protocol = "HTTP"
    address         = "1.1.1.1" # add an ip
    port            = "80"
    type            = "ipv4"
  }
  depends_on = [huaweicloud_waf_cloud_instance.myWAF]
}
#DNSSSSSSSSS
resource "huaweicloud_dns_zone" "DNSmyPublicZone" {
  name        = "phoebe.cl"
  description = "the dns public zone for the waf"
  ttl         = 30
  zone_type   = "public"
}

resource "huaweicloud_dns_recordset" "PhoebeRecordSet_A" {
  zone_id     = huaweicloud_dns_zone.DNSmyPublicZone.id
  name        = "dvwa.phoebe.cl"
  type        = "A"
  description = "hecho desde terraform"
  ttl         = 30
  records     = ["110.238.69.16"] # ip publica de la maquina virtual
}
resource "huaweicloud_dns_recordset" "PhoebeRecordSet_CNAME" {
  zone_id     = huaweicloud_dns_zone.DNSmyPublicZone.id
  name        = "dvwa2.phoebe.cl"
  type        = "CNAME"
  description = "hecho desde terraform"
  ttl         = 30
  records     = ["940219fa2389490aa6558d6559cb2d82.vip1.huaweicloudwaf.com"] #CNAME del WAF
}

# Variables
variable "ak" {
  type = string
}

variable "sk" {
  type = string
}

variable "region" {
  type = string
}
variable "enterprise_project_id" {
  type = string
}

#TODO1: AGREGAR BOB CON HSS 
#TODO2: AGREGAR ER, MODIFICAR EL CFW PARA QUE USE EL ER, AGREGAR AL ER LAS VPC. ALICE EN VPC-1 Y LUEGO BOB EN VPC-2

