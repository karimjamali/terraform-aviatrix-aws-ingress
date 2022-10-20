# Aviatrix AWS Ingress with Wordpress

![aviatrix_logo_final_reverse (1)](https://user-images.githubusercontent.com/16576150/185464537-8cb09a38-d0d8-41fe-b400-5dd863eacf91.png)

## Summary

This repository builds out an ingress scenario leveraging Aviatrix on AWS using a 3-tier Wordpress Application.

It builds the following:

* Aviatrix Transit in us-east-1 with FireNet having Palo Alto Networks VM-series Firewalls.
* Aviatrix Transit in us-east-2 without FireNet.  
* 3 Spoke VPCs (Ingress, Proxy, Web) attached to Aviatrix Transit in us-east-1  
* 1 Spoke VPC (Database) attached to the Aviatrix Transit in us-east-2
* Wordpress Application (Proxy, Web and Database)
* Central Application Load Balancer (ALB) configured in the Ingress VPC
* Proxy LB (NLB) that services the Proxy tier of the application
* 3 x Ubuntu VMs (Proxy, Web, Database) that are private and get Outbound internet access through PAN FWs.
* Palo Alto Firewalls also are bootstrapped as part of the Terraform Code

## ComponentVersion

* Aviatrix Controller UserConnect-6.8.1148  
* Versions of the Aviatrix, and AWS providers can all be found in versions.tf.

## Dependencies

* Software version requirements met
* Aviatrix Controller & Copilot (Highly Recommended) need to be up and running
* Onboarding the AWS Account is automated
* Sufficient limits in place for CSPs and regions in scope (EIPs, Compute quotas, etc.)
* Active subscriptions for the NGFW firewall images in scope

## Architecture

### Overall Design

![Ingress + uSeg + FireNet - Overall Design (2)](https://user-images.githubusercontent.com/16576150/185468311-6271e5c3-42d8-45f5-9c93-5e29ccbcd287.png)

### Inbound Traffic Flow

![Ingress + uSeg + FireNet - Inbound Traffic Flow (1)](https://user-images.githubusercontent.com/16576150/185456127-3937f726-4f46-4e3c-8dce-b4bfc464824e.png)

### Outbound Traffic Flow

![Ingress + uSeg + FireNet - Outbound Security (2)](https://user-images.githubusercontent.com/16576150/185456214-0f724b5b-cc83-4a4c-b8e9-f94d9d4da762.png)

## Usage

aws_account_name: This is the name of the aws account onboarded to the Aviatrix controller.
unique_s3_bucket_name: This is a unique name that will be used to create an s3 bucket for the PALO fw bootstrap files. Details on the process (automated for you by this module) can be found here: https://docs.aviatrix.com/HowTos/bootstrap_example.html

```terraform
module "aws-ingress" {
  source                = "karimjamali/aws-ingress/aviatrix"
  version               = "1.15.0"
  aws_account_name = ""
  unique_s3_bucket_name = ""

  providers = {
    aws.region-2 = aws.region-2
  }
}

provider "aviatrix" {
  username                = "your_controller_username"
  password                = "your_controller_username"
  controller_ip           = "your_controller_ip"
}

provider "aws" {
  region  = "us-east-1"
}

provider "aws" {
  alias   = "region-2"
  region  = "us-east-2
}
```

## Additional Important Variables to Understand

Please note that these are not required to run the code but to make some changes.

* Ubuntu VMs (Proxy, Web, and DB) have a username of ubuntu and their password is in the variable ubuntu_vms_password
* Variables proxy_lb_1 and proxy_lb_2 are the static addresses configured on the NLB.
* Variables pan_fw_username and pan_fw_password hold the values for the username and password for PAN FWs. You can't change the values unless you change the bootstrap package. The pan_fw_username is admin and pan_fw_password is Aviatrix123#
* The VMs are private, however they get outbound internet connectivity through the PAN FWs, thus bootstrapping is required for the VMs to download the packages to run Wordpress.
