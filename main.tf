terraform {
  cloud {
    organization = "Your_Org_Name"

    workspaces {
      name = "multi-cloud-infra"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  required_version = ">= 1.3.0"
}

provider "aws" {
  region = "us-east-1"
}

provider "google" {
  project = var.gcp_project
  region  = "us-central1"
}

provider "azurerm" {
  features {}
}

variable "gcp_project" {
  description = "GCP project ID"
  type        = string
}

resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0" # Update with latest Amazon Linux AMI
  instance_type = "t2.micro"
}

resource "google_compute_instance" "web" {
  name         = "web-instance"
  machine_type = "e2-micro"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }
}

resource "azurerm_virtual_machine" "web" {
  name                  = "web-vm"
  location              = "East US"
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.web.id]
  vm_size               = "Standard_B1s"

  storage_os_disk {
    name              = "web-vm-os-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "web-vm"
    admin_username = "adminuser"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}
