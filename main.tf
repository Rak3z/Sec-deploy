provider "huaweicloud" {
  region      = var.region
  access_key  = var.ak
  secret_key  = var.sk
  auth_url    = "https://iam.${var.region}.myhuaweicloud.com/v3"
}

# list availability zones 
data "huaweicloud_availability_zones" "zones" {}


# VPC's -------------------------------------------------------------------------

# Create a VPC's
resource "huaweicloud_vpc_v1" "vpc_v1" {
  name = "vpc-tf-1"
  cidr = "192.168.0.0/16"
}
resource "huaweicloud_vpc_v1" "vpc_v2" {
  name = "vpc-tf-2"
  cidr = "192.169.0.0/16"
}
# Create subnets
resource "huaweicloud_vpc_subnet_v1" "subnet_v1" {
  name       = "subnet-tf-test"
  cidr       = "192.168.0.0/24"
  gateway_ip = "192.168.0.1"
  vpc_id     = huaweicloud_vpc_v1.vpc_v1.id
  depends_on = [huaweicloud_vpc_v1.vpc_v1]
}
resource "huaweicloud_vpc_subnet_v1" "subnet_v2" {
  name       = "subnet-tf-test"
  cidr       = "192.169.0.0/24"
  gateway_ip = "192.169.0.1"
  vpc_id     = huaweicloud_vpc_v1.vpc_v2.id
  depends_on = [huaweicloud_vpc_v1.vpc_v2]
}
# Create Security Groups and rule ssh
# Security group
resource "huaweicloud_networking_secgroup_v2" "secgroup_1" {
  name        = "secgroup_tf_1"
  description = "My neutron security group"
}
#rule
resource "huaweicloud_networking_secgroup_rule_v2" "secgroup_rule_1" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = huaweicloud_networking_secgroup_v2.secgroup_1.id
  depends_on = [huaweicloud_networking_secgroup_v2.secgroup_1]
}


# ECS's ------------------------------------------------------------------------

# Create ECS
resource "huaweicloud_compute_instance_v2" "bob" {
  name              = "bob"
  image_name        = "Ubuntu 18.04 server 64bit"
  flavor_name       = "s6.medium.4"
  security_groups   = [ huaweicloud_networking_secgroup_v2.secgroup_1.name ]
  availability_zone = data.huaweicloud_availability_zones.zones.names[0]

  network {
    uuid = huaweicloud_vpc_subnet_v1.subnet_v2.id
  }
  depends_on = [
    huaweicloud_vpc_subnet_v1.subnet_v2,
    huaweicloud_networking_secgroup_v2.secgroup_1
  ]
}
resource "huaweicloud_compute_instance_v2" "alice" {
  name              = "alice"
  image_name        = "Ubuntu 18.04 server 64bit"
  flavor_name       = "s6.medium.4"
  security_groups   = [ huaweicloud_networking_secgroup_v2.secgroup_1.name ]
  availability_zone = data.huaweicloud_availability_zones.zones.names[0]

  network {
    uuid = huaweicloud_vpc_subnet_v1.subnet_v1.id
  }
  depends_on = [
    huaweicloud_vpc_subnet_v1.subnet_v1,
    huaweicloud_networking_secgroup_v2.secgroup_1
  ]
}


# EIP --------------------------------------------------------------------------

#create EIP
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
#asociate EIP to ECS
resource "huaweicloud_compute_eip_associate" "associated" {
  public_ip   = huaweicloud_vpc_eip.myElasticIP.address
  instance_id = huaweicloud_compute_instance_v2.alice.id
  depends_on = [ 
    huaweicloud_vpc_eip.myElasticIP, 
    huaweicloud_compute_instance_v2.alice
    ]
}




# ER and CFW -------------------------------------------------------------------

#Enterprise router creation
resource "huaweicloud_er_instance" "MyER" {
    availability_zones = data.huaweicloud_availability_zones.zones.names
    name = "enterpriseRouter" 
    asn = 64512
}

#Create CFW with er protection
resource "huaweicloud_cfw_firewall" "myCFW" {
  name = "CFW-tf"
  charging_mode = "postPaid"
  east_west_firewall_inspection_cidr = "172.16.1.0/24"
  east_west_firewall_er_id           = huaweicloud_er_instance.MyER.id
  east_west_firewall_mode            = "er"

  flavor {
    version = "Professional"
  }
}
#make CFW protect eip
resource "huaweicloud_cfw_eip_protection" "eipProtection" {
  object_id =  huaweicloud_cfw_firewall.myCFW.protect_objects[0].object_id
  protected_eip {
      id          = huaweicloud_vpc_eip.myElasticIP.id
      public_ipv4 = huaweicloud_vpc_eip.myElasticIP.address
    }
  depends_on = [
    huaweicloud_vpc_eip.myElasticIP, 
    huaweicloud_cfw_firewall.myCFW
    ]
}

#make in and out route tables
resource "huaweicloud_er_route_table" "route_in" {
  instance_id = huaweicloud_er_instance.MyER.id
  name = "Route_table_in" 
  description = "Route table created by terraform"
  depends_on = [huaweicloud_er_instance.MyER]
}

resource "huaweicloud_er_route_table" "route_out" {
  instance_id = huaweicloud_er_instance.MyER.id
  name = "Route_table_out" 
  description = "Route table created by terraform"
  depends_on = [huaweicloud_er_instance.MyER]
}

#VPC and CFW attachments
resource "huaweicloud_er_vpc_attachment" "vpc2_attach" {
  instance_id = huaweicloud_er_instance.MyER.id
  vpc_id      = huaweicloud_vpc_v1.vpc_v2.id 
  subnet_id   = huaweicloud_vpc_subnet_v1.subnet_v2.id
  name        = "vpc2_attachment"
  description = "VPC attachment created by terraform"
  auto_create_vpc_routes = true
  depends_on = [
    huaweicloud_er_instance.MyER,
    huaweicloud_vpc_v1.vpc_v2
    ]
}

resource "huaweicloud_er_vpc_attachment" "vpc1_attach" {
  instance_id = huaweicloud_er_instance.MyER.id
  vpc_id      = huaweicloud_vpc_v1.vpc_v1.id 
  subnet_id   = huaweicloud_vpc_subnet_v1.subnet_v1.id
  name        = "vpc1_attachment"
  description = "VPC attachment created by terraform"
  auto_create_vpc_routes = true
  depends_on = [
    huaweicloud_er_instance.MyER,
    huaweicloud_vpc_v1.vpc_v1
    ]
}

#since the autoattachment is there we only need to find it
data "huaweicloud_er_attachments" "auto_attach" { #this part currently I think is not working
  instance_id = huaweicloud_er_instance.MyER.id 
  name        = "cfw-er-auto-attach"
  depends_on  = [huaweicloud_er_instance.MyER, huaweicloud_cfw_firewall.myCFW]
}

# add asociations in out table
resource "huaweicloud_er_association" "CFW_attach" {
  instance_id = huaweicloud_er_instance.MyER.id
  route_table_id = huaweicloud_er_route_table.route_out.id
  attachment_id  = data.huaweicloud_er_attachments.auto_attach.attachments[0].id #change this line to make it work
  depends_on = [
    huaweicloud_er_instance.MyER,
    data.huaweicloud_er_attachments.auto_attach
    ]
}

# propagation for VPC in out table
resource "huaweicloud_er_propagation" "vpc1_out_attach" {
  instance_id = huaweicloud_er_instance.MyER.id
  route_table_id = huaweicloud_er_route_table.route_out.id
  attachment_id  = huaweicloud_er_vpc_attachment.vpc1_attach.id
  depends_on = [
    huaweicloud_er_instance.MyER, 
    huaweicloud_er_vpc_attachment.vpc1_attach
    ]
}
resource "huaweicloud_er_propagation" "vpc2_out_attach" {
  instance_id = huaweicloud_er_instance.MyER.id
  route_table_id = huaweicloud_er_route_table.route_out.id
  attachment_id  = huaweicloud_er_vpc_attachment.vpc2_attach.id
  depends_on = [
    huaweicloud_er_instance.MyER, 
    huaweicloud_er_vpc_attachment.vpc2_attach
    ]
}

# configure in and route tables attachments
resource "huaweicloud_er_association" "rt_attach_vpc1" {
  instance_id = huaweicloud_er_instance.MyER.id
  route_table_id = huaweicloud_er_route_table.route_in.id
  attachment_id  = huaweicloud_er_vpc_attachment.vpc1_attach.id
  depends_on = [huaweicloud_er_vpc_attachment.vpc1_attach]
}
resource "huaweicloud_er_association" "rt_attach_vpc2" {
  instance_id = huaweicloud_er_instance.MyER.id
  route_table_id = huaweicloud_er_route_table.route_in.id
  attachment_id  = huaweicloud_er_vpc_attachment.vpc2_attach.id
  depends_on = [huaweicloud_er_vpc_attachment.vpc2_attach]
}

# configure routes in routes tables
resource "huaweicloud_er_static_route" "route_vpc2_for_attach" {
  route_table_id = huaweicloud_er_route_table.route_in.id
  destination    = "192.169.0.0/16" 
  attachment_id  = huaweicloud_er_vpc_attachment.vpc2_attach.id
  depends_on = [huaweicloud_er_vpc_attachment.vpc2_attach]
}
resource "huaweicloud_er_static_route" "route_vpc1_for_attach" {
  route_table_id = huaweicloud_er_route_table.route_in.id
  destination    = "192.168.0.0/16" 
  attachment_id  = huaweicloud_er_vpc_attachment.vpc1_attach.id
  depends_on = [huaweicloud_er_vpc_attachment.vpc1_attach]
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

#TODO1: AGREGAR WAF, AGREGAR BOB CON HSS 
# el bob con hss se usa ansible pero preguntare primero como se deberia hacer

# el waf no se pudo completar por un error que aun no soluciono
# con respecto al tema del waf con el DNS, hay que colocar la ip asignada
# el dns funca, lo que no funca es agregar el dominio al waf pues dice por alguna 
    # razon que no se esta suscrito al servicio de waf, me llama la atencion que 
    # ademas ni siquiera piide un id de waf o algo

# hay que editar probablemente las route tables de las vpc o algo para revisar
    # como se haría
