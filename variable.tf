# This file contains the variable definitions for the Terraform configuration.
variable "client_id" {
  description = "Azure client ID"
  type        = string
  default =    "" //  # Replace with your actual client ID
}

variable "client_secret" {
  description = "Azure client secret"
  type        = string
  default     = "" //  # Replace with your actual client secret
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
  default = ""// Replace with your actual subscription ID
}

variable "tenant_id" {
  description = "Azure tenant ID"
  type        = string
    default = "" // Replace with your actual tenant ID
}
variable "location" {
  description = "Azure location"
  type        = string
  default     = "Central US"
}
# variable "public_key" {
#   description = "Public key for SSH access"
#   type        = string
#   default     = ""
# }
variable "admin_password" {
  description = "The admin password for the Windows VM."
  type        = string
  default = "siba@1234" # Ensure this meets Azure's password complexity requirements"
}
# variable "azurerm_resource_group_name" {
#   description = "The name of the Azure Storage Account."
#   type        = string
#   default     = "terraform_traingroup-1"
  
# }