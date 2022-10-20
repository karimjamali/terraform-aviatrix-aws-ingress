variable "aws_account_number" {
  default = null
}

variable "unique_s3_bucket_name" {
  description = "This is the bucket that includes the bootsrap information for the PAN FW"
}

variable "aws_account_name" {}

#This variable creates firenet if true
variable "firenet" {
  default = true
}

variable "proxy_lb_ip1" {
  default = "10.1.0.66"
}

variable "proxy_lb_ip2" {
  default = "10.1.0.82"
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
