variable "ssh_host" {
  description = "Host to deploy to."
  type        = string
}

variable "registry" {
  description = "ECR registry that holds the app image."
  type        = string
  default     = "313336455033.dkr.ecr.eu-west-1.amazonaws.com"
}

variable "image_tag" {
  description = "Tag of the app image in ECR to deploy."
  type        = string
}

variable "smtp_host" {
  description = "SMTP server the app sends mail through."
  type        = string
}

variable "smtp_username" {
  description = "Username for the SMTP server."
  type        = string
}

variable "smtp_password" {
  description = "Password for the SMTP server."
  type        = string
  sensitive   = true
}

variable "hetzner_backup_window" {
  description = "UTC Hetzner backup window in HH-HH format."
  type        = string

  validation {
    condition     = can(regex("^\\d{2}-\\d{2}$", var.hetzner_backup_window))
    error_message = "Hetzner backup window must use HH-HH format."
  }
}
