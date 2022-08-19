variable "avx_controller_ip" {
  description = "AVX Controller IP Address"
  default = ""
}

variable "avx_controller_username" {
  description = "AVX Controller username"
  default = ""
}
variable "avx_controller_password" {
  description = "AVX Controller password"
  default = ""
}

variable "aws_account_number" {
  default = ""
}

variable "aws_acess_key" {
  description = "AWS Access Key"
  default = ""
}

variable "aws_secret_key" {
  description = "AWS Secret Key"
  default = ""
}

variable "home_ip" {
  description = "This is the IP Address from which you are accessing the setup use IP/Mask for example 1.1.1.1/32"
  default = ""
}

variable "role_fw_s3" {
  description = "The role that allows the FW Instances to read S3 for bootstrapping"
  default = ""
}

variable "pan_fw_s3_bucket_bootstrap" {
  description = "This is the bucket that includes the bootsrap information for the PAN FW"
  default = ""
}


variable "aws_region_1" {
  default = "us-east-1"
}  

variable "aws_region_2" {
  default = "us-east-2"
}  




variable "aws_account_name" {
  default = "aws-account"
}


#This variable creates firenet if true
variable "firenet" {
  default = true
}

variable "proxy-lb-ip1" {
    default = "10.1.0.44"
}

variable "proxy-lb-ip2" {
    default = "10.1.0.53"
}

variable "ubuntu_vms_password" {
    default = "Aviatrix123#"
}

variable "ha_setup" {
    default = false
}

variable "pan_fw_username" {
    default = "admin"
  
}

variable "pan_fw_password" {
    default = "Aviatrix123#"
}





