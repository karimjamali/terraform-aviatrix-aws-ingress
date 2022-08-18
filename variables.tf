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

variable "pan_fw_s3_bucket_bootstrap" {
    default = "s3-kj-panw-bucket-bootstrap"
}



