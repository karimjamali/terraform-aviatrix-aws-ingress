terraform {
  required_providers {
    aviatrix = {
      source  = "AviatrixSystems/aviatrix"
      version = "~> 2.24"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
      configuration_aliases = [
        aws.region-2
      ]
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.2.3"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 3.4.0"
    }
  }
  required_version = ">= 1.0"
}
