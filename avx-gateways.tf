#Adding aws-account to the controller
resource "aviatrix_account" "aws-account" {
  account_name       = var.aws_account_name
  cloud_type         = 1
  aws_account_number = var.aws_account_number
  aws_iam            = true
  aws_role_app       = "arn:aws:iam::${var.aws_account_number}:role/aviatrix-role-app"
  aws_role_ec2       = "arn:aws:iam::${var.aws_account_number}:role/aviatrix-role-ec2"
}



#creation of us-east-1-transit-1
module "mc_transit_aws-us-east-1-transit-1" {
  source  = "terraform-aviatrix-modules/mc-transit/aviatrix"
  
  
  cloud                  = "AWS"
  cidr                   = "10.100.0.0/16"
  region                 = "us-east-1"
  account                = aviatrix_account.aws-account.account_name
  enable_transit_firenet = true
  insane_mode = true
  enable_segmentation = true
  ha_gw = var.ha_setup
}

# Adding the Palo Alto Firewalls (FWs). 
#Setting variable firenet to false will not create the Firewalls
module "firenet_1" {
  count = var.firenet ? 1 : 0
  source  = "terraform-aviatrix-modules/mc-firenet/aviatrix"
  keep_alive_via_lan_interface_enabled = true
  transit_module = module.mc_transit_aws-us-east-1-transit-1
  firewall_image = "Palo Alto Networks VM-Series Next-Generation Firewall Bundle 1"
  bootstrap_bucket_name_1   = var.pan_fw_s3_bucket_bootstrap
  iam_role_1 = var.role_fw_s3
  egress_enabled = true
  username = var.pan_fw_username
  password = var.pan_fw_password
  
}
/*
#Inducing a timer so the FW is ready for Vendor Integration
resource "time_sleep" "wait_500_seconds" {
  depends_on = [module.firenet_1]
  create_duration = "500s"
}
*/

#Vendor Integration: Pushing the routes to FW1

data "aviatrix_firenet_vendor_integration" "fw1" {
  vpc_id        = module.mc_transit_aws-us-east-1-transit-1.vpc.vpc_id
  instance_id   = module.firenet_1[0].aviatrix_firewall_instance[0].instance_id
  vendor_type   = "Palo Alto Networks VM-Series"
  public_ip     = module.firenet_1[0].aviatrix_firewall_instance[0].public_ip
  username = var.pan_fw_username
  password = var.pan_fw_password
  save = true
  number_of_retries = 5
  depends_on = [
    module.firenet_1
  ]
}

#Vendor Integration: Pushing the routes to FW2
data "aviatrix_firenet_vendor_integration" "fw2" {
  count = var.ha_setup ? 1 : 0
  vpc_id        = module.mc_transit_aws-us-east-1-transit-1.vpc.vpc_id
  instance_id   = module.firenet_1[0].aviatrix_firewall_instance[1].instance_id
  vendor_type   = "Palo Alto Networks VM-Series"
  public_ip     = module.firenet_1[0].aviatrix_firewall_instance[1].public_ip
  number_of_retries = 5
  username = var.pan_fw_username
  password = var.pan_fw_password
  save= true
  depends_on = [
    module.firenet_1
  ]
}


#Creating the Spoke that hosts the Proxy VM
module "spoke_aws-us-east-1-proxy" {
  source  = "terraform-aviatrix-modules/mc-spoke/aviatrix"
  cloud           = "AWS"
  name            = "aws-us-east-1-proxy"
  cidr            = "10.1.0.0/16"
  region          = "us-east-1"
  account         = aviatrix_account.aws-account.account_name
  transit_gw      = module.mc_transit_aws-us-east-1-transit-1.transit_gateway.gw_name
  ha_gw = var.ha_setup
  
}

# Creating the Spoke that hosts the Web VM
module "spoke_aws-us-east-1-web" {
  source  = "terraform-aviatrix-modules/mc-spoke/aviatrix"
  

  cloud           = "AWS"
  name            = "aws-us-east-1-web"
  cidr            = "10.2.0.0/16"
  region          = "us-east-1"
  account         = aviatrix_account.aws-account.account_name
  transit_gw      = module.mc_transit_aws-us-east-1-transit-1.transit_gateway.gw_name
  ha_gw = var.ha_setup
}

#Vendor Integration: Creating the Spoke that hosts the DB VM
module "spoke_aws-us-east-1-centralized-ingress" {
  source  = "terraform-aviatrix-modules/mc-spoke/aviatrix"
  cloud           = "AWS"
  name            = "aws-us-east-1-centralized-ingress"
  cidr            = "10.109.0.0/16"
  region          = "us-east-1"
  account         = aviatrix_account.aws-account.account_name
  transit_gw      = module.mc_transit_aws-us-east-1-transit-1.transit_gateway.gw_name 
  ha_gw = var.ha_setup
}



## Using data to get the public route tables that will be protected by PSF
data "aws_route_table" "public_rt1" {
  subnet_id = module.spoke_aws-us-east-1-centralized-ingress.vpc.public_subnets[0].subnet_id
}

data "aws_route_table" "public_rt2" {
  subnet_id = module.spoke_aws-us-east-1-centralized-ingress.vpc.public_subnets[1].subnet_id
}




## PSF GW creation in the centralized ingress VPC

resource "aviatrix_gateway" "centralized-ingress-psf-gateway" {
  cloud_type                                  = 1
  account_name                                = aviatrix_account.aws-account.account_name
  gw_name                                     = "aws-us-east-1-central-ingress-psf-gw"
  vpc_id                                      = module.spoke_aws-us-east-1-centralized-ingress.vpc.vpc_id
  vpc_reg                                     = "us-east-1"
  gw_size                                     = "t2.micro"
  subnet                                      = "10.109.0.64/26"
  zone                                        = "us-east-1a"
  enable_public_subnet_filtering              = true
  public_subnet_filtering_guard_duty_enforced = true
  public_subnet_filtering_route_tables = [data.aws_route_table.public_rt1.id, data.aws_route_table.public_rt2.id ]
  enable_encrypt_volume                       = true
 
  
}

#creation of us-east-2-transit-1
module "mc_transit_aws-us-east-2-transit-1" {
  source  = "terraform-aviatrix-modules/mc-transit/aviatrix" 
  cloud                  = "AWS"
  cidr                   = "10.120.0.0/16"
  region                 = "us-east-2"
  account                = aviatrix_account.aws-account.account_name
  enable_transit_firenet = true
  insane_mode = true
  enable_segmentation = true
  ha_gw = var.ha_setup
}

# Configuring transit peering between the two transits
module "transit-peering" {
  source  = "terraform-aviatrix-modules/mc-transit-peering/aviatrix"
  version = "1.0.6"
  transit_gateways = [
    module.mc_transit_aws-us-east-1-transit-1.transit_gateway.gw_name,
    module.mc_transit_aws-us-east-2-transit-1.transit_gateway.gw_name 
  ]
  
}

#Creating the Spoke that hosts the DB VM
module "spoke_aws-us-east-2-database" {
  source  = "terraform-aviatrix-modules/mc-spoke/aviatrix"
  cloud           = "AWS"
  name            = "aws-us-east-2-database"
  cidr            = "10.3.0.0/16"
  region          = "us-east-2"
  account         = aviatrix_account.aws-account.account_name
  transit_gw      = module.mc_transit_aws-us-east-2-transit-1.transit_gateway.gw_name
  ha_gw = var.ha_setup
}




   
