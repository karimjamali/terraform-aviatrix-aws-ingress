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

## PAN FWs Bootstrapping

Firewall Bootstrapping is a key pillar in the architecture as it is required for the 3 x VMs (Proxy, Web and DB) to download the required packages in a secure fashion. Thus, Firewall Bootstrapping needs to take place before the creation of the 3 instances.
For FW Bootstrapping you need to follow the steps found here: https://docs.aviatrix.com/HowTos/bootstrap_example.html
In a nutshell, you need to create the IAM Role, attach it to the PAN FW Instance(s) and put the relevant files in the S3 directory.

S3 directory should look like the below screenshot. The variable name for the S3 bucket is pan_fw_s3_bucket_bootstrap and should be changed to match your bucket name.
![Screen Shot 2022-08-16 at 9 00 32 PM](https://user-images.githubusercontent.com/16576150/185457948-b163ec9f-b0ab-47aa-99d9-e0ae12680e62.png)

Contents of the config folder should look like the below screenshot. Please note that I have attached both files bootstrap.xml and init.cfg to the github repository for your consumption.
![Screen Shot 2022-08-16 at 9 00 48 PM](https://user-images.githubusercontent.com/16576150/185458081-8b46eb26-238c-4bb6-b025-bf0484504cf3.png)

## Architecture

### Overall Design

![Ingress + uSeg + FireNet - Overall Design (2)](https://user-images.githubusercontent.com/16576150/185468311-6271e5c3-42d8-45f5-9c93-5e29ccbcd287.png)

### Inbound Traffic Flow

![Ingress + uSeg + FireNet - Inbound Traffic Flow (1)](https://user-images.githubusercontent.com/16576150/185456127-3937f726-4f46-4e3c-8dce-b4bfc464824e.png)

### Outbound Traffic Flow

![Ingress + uSeg + FireNet - Outbound Security (2)](https://user-images.githubusercontent.com/16576150/185456214-0f724b5b-cc83-4a4c-b8e9-f94d9d4da762.png)

## Usage

aws_account_name: This is the name of the aws account onboarded to the Aviatrix controller.
unique_s3_bucket_name: This is a unique name that will be used to create an s3 bucket for the PALO fw boostrap files.

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
