#--------------------------------------------------------------------------------
# Vasyl Gnatiuk "vasyl.gnatiuk@gmail.com"
#--------------------------------------------------------------------------------

// Configure the Google Cloud provide
variable "credentials_file_path" {
  description = "Path to the JSON file used to describe your account credentials"
  default     = "~/.config/gcloud/wordpress-248302-e69b3701643e.json"
}

variable "project_name" {
  default = "wordpress-248302"
}

variable "region" {
  default = "us-east1"
}

variable "region_zone" {
  default = "us-east1-d"
}

// Create VPC
variable "name" {
  default     = "dev"
}
// Create Subnet
variable "subnet_cidr" {
  default     = "10.10.0.0/16"
}

// VPC firewall configuration

variable "fw" {
  default = "default-allow-http-80"
}

variable "allow_ports" {
  default = "80"
}

// VM Instance
variable "machine_type" {
  default = "g1-small"
}

variable "app_name" {
  default = "wordpress"
}

variable "ubuntu-1804-lts" {
  default = "ubuntu-minimal-1804-lts"
}


// VM Instance Group
variable "group" {
  default = "frontend-group"
}

// Compute backend service
variable "service" {
  default = "my-app-service"
}

// Create Google SQL Database Instance
variable "sql_db" {
  default = "MYSQL_5_7"
}
