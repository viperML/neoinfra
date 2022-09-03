variable "compartment_id" {
  type        = string
  description = "OCI Compartment OCID"
}

variable "oci_key_id" {
  type        = string
  description = "Vault Key OCID"
}

variable "cloudflare_email" {
  type        = string
  description = "Email of the Cloudflare account"
}

variable "cloudflare_api_token" {
  type        = string
  description = "API Key for Cloudflare DNS"
}

variable "cloudflare_zone_id" {
  type        = string
  description = "Zone ID for Cloudflare"
}
