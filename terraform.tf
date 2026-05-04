terraform {
  required_providers {
    crczp = {
      source = "cyberrangecz/crczp"
    }
    openstack = {
      source = "terraform-provider-openstack/openstack"
    }
  }

  backend "s3" {
    endpoint                    = "gm7ve.upcloudobjects.com"
    bucket                      = "cshub-states"
    encrypt                     = true
    force_path_style            = true
    key                         = var.NAME
    region                      = "europe-2"
    skip_credentials_validation = true
    skip_region_validation      = true
    workspace_key_prefix        = "images-ci"
  }
}

provider "crczp" {
}

provider "openstack" {
}

variable "PROJECT_URL" {}
variable "REV" {}
variable "NAME" {}
variable "TYPE" {}
variable "DISTRO" {}
variable "GUI_ACCESS" {}
variable "IMAGE_LOCAL_PATH" {
  type    = string
  default = null
}

module "topology" {
  source           = "git::https://github.com/cyberrangecz/terraform-crczp-image-testing-topology.git"
  project_url      = var.PROJECT_URL
  rev              = var.REV
  image_name       = var.NAME
  os_type          = var.TYPE
  os_distro        = var.DISTRO
  gui_access       = var.GUI_ACCESS
  image_local_path = var.IMAGE_LOCAL_PATH
  image_properties_override = {
    hw_firmware_type = "uefi"
    hw_machine_type  = "q35"
  }
}
