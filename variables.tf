variable "aws_account_number" {
  default = null
}

variable "pan_fw_s3_bucket_bootstrap" {
  description = "This is the bucket that includes the bootsrap information for the PAN FW"
  default     = ""
}

variable "aws_account_name" {}

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
