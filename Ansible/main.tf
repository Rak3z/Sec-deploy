provider "huaweicloud" {
  region      = var.region
  access_key  = var.ak
  secret_key  = var.sk
  auth_url    = "https://iam.${var.region}.myhuaweicloud.com/v3"
}

# Get a list of availability zones
data "huaweicloud_availability_zones" "zones" {}

# Create a VPC, Network and Subnet
resource "huaweicloud_vpc_v1" "vpc_v1" {
  name = "vpc-tf-test"
  cidr = "192.168.0.0/16"
}
# create a KPS pair (SSH)
resource "huaweicloud_kps_keypair" "terraform_generated_key" {
  name            = "terraform-generated-key"
  encryption_type = "default"
  scope           = "account"
  public_key      = file("/ssh/id_rsa.pub")
  private_key     = file("/ssh/id_rsa")
}

resource "huaweicloud_vpc_subnet_v1" "subnet_v1" {
  name       = "subnet-tf-test"
  cidr       = "192.168.0.0/24"
  gateway_ip = "192.168.0.1"
  vpc_id     = huaweicloud_vpc_v1.vpc_v1.id
}

# Create Security Group and rule ssh
resource "huaweicloud_networking_secgroup_v2" "secgroup_1" {
  name        = "secgroup_tf_1"
  description = "My neutron security group"
}

resource "huaweicloud_networking_secgroup_rule_v2" "secgroup_rule_1" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = huaweicloud_networking_secgroup_v2.secgroup_1.id
}

# Create ECS
resource "huaweicloud_compute_instance" "bob" {
  name              = "bob"
  image_name        = "Ubuntu 18.04 server 64bit"
  flavor_name       = "s6.medium.4"
  key_pair           = "terraform-generated-key"
  security_groups   = [ huaweicloud_networking_secgroup_v2.secgroup_1.name ]
  availability_zone = data.huaweicloud_availability_zones.zones.names[0]

  user_data = "IyEvYmluL2Jhc2gKc3VkbyBhcHQgdXBkYXRlCnN1ZG8gYXB0IHVwZ3JhZGUKc3VkbyBhZGQtYXB0LXJlcG9zaXRvcnkgcHBhOmRlYWRzbmFrZXMvcHBhCnN1ZG8gYXB0IGluc3RhbGwgcHl0aG9uMy44"
  network {
    uuid = huaweicloud_vpc_subnet_v1.subnet_v1.id
  }
  depends_on = [
    huaweicloud_vpc_subnet_v1.subnet_v1,
    huaweicloud_networking_secgroup_v2.secgroup_1,
    huaweicloud_kps_keypair.terraform_generated_key
  ]
}

resource "huaweicloud_vpc_eip" "myElasticIP" {
  publicip {
    type = "5_bgp"
  }

  bandwidth {
    share_type  = "PER"
    name        = "tf-testing"
    size        = 250
    charge_mode = "traffic"
  }
}

resource "huaweicloud_compute_eip_associate" "associated" {
  public_ip   = huaweicloud_vpc_eip.myElasticIP.address
  instance_id = huaweicloud_compute_instance.bob.id
  depends_on = [ huaweicloud_vpc_eip.myElasticIP, huaweicloud_compute_instance.bob ]
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

data "huaweicloud_kps_keypairs" "tf_key_out"{
  name = "terraform-generated-key"
}
#salida
output "eipBob" {
  value = "[ecs]\n${huaweicloud_vpc_eip.myElasticIP.address} ansible_user=root ansible_ssh_private_key_file=./ssh/id_rsa"
}
