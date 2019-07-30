#--------------------------------------------------------------------------------
# Vasyl Gnatiuk "vasyl.gnatiuk@gmail.com"
#--------------------------------------------------------------------------------

// Configure the Google Cloud provide
provider "google" {
  credentials = "${file("${var.credentials_file_path}")}"
  project     = "${var.project_name}"
  region      = "${var.region}"
  zone        = "${var.region_zone}"
}


// Create VPC
resource "google_compute_network" "vpc" {
  name                    = "${var.name}-vpc"
  auto_create_subnetworks = "false"
}


// Create Subnet
resource "google_compute_subnetwork" "subnet" {
  name          = "${var.name}-subnet"
  ip_cidr_range = "${var.subnet_cidr}"
  network       = "${google_compute_network.vpc.self_link}"
  region        = "${var.region}"
}


// VPC firewall configuration
resource "google_compute_firewall" "firewall" {
  name         = "${var.fw}"
  network      = "${google_compute_network.vpc.name}"
  description  = "Allow port 80 access to http-server"

  allow {
    protocol   = "tcp"
    ports      = ["${var.allow_ports}"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}


// VM Instance Template
resource "google_compute_instance_template" "dev" {
  name                    = "${var.group}-tmpl"
  machine_type            = "${var.machine_type}"
  metadata_startup_script = "${file("scripts/startup-script.sh")}"
  tags                    = ["http-server"]
  
    // boot disk
  disk {
      source_image        = "${var.ubuntu-1804-lts}"
  }

	  
  // networking
  network_interface {
    subnetwork = "${google_compute_subnetwork.subnet.self_link}"
    access_config {
    }  
     network    = "${google_compute_network.vpc.self_link}" // provider google
  }

  lifecycle {
    create_before_destroy = true
  }

  service_account {
    scopes      = ["userinfo-email", "cloud-platform"]
  }

}


// VM Instance Group

resource "google_compute_instance_group_manager" "dev" {
  name               = "${var.group}"
  base_instance_name = "${var.group}"
  target_size        = "2"
  instance_template  = "${google_compute_instance_template.dev.self_link}"
  wait_for_instances = true

 named_port {
    name = "http"
    port = "80"
  }
}


// Health Check
resource "google_compute_http_health_check" "dev" {
 name =  "health-check"

 timeout_sec        = 1
 check_interval_sec = 5

 port = "80"
 request_path     = "/"   
}


// Compute backend service
resource "google_compute_backend_service" "dev" {
  name             = "${var.service}"
  protocol         = "HTTP"
  timeout_sec      = 10
  session_affinity = "NONE"

  backend {
    group = "${google_compute_instance_group_manager.dev.instance_group}"
  }

  health_checks = ["${google_compute_http_health_check.dev.self_link}"]
}


// Create URL Map
resource "google_compute_url_map" "dev" {
  name            = "${var.service}-map"
  default_service = "${google_compute_backend_service.dev.self_link}"
}

// Create HTTP Proxy
resource "google_compute_target_http_proxy" "dev" {
  name            = "${var.service}-proxy"
  url_map         = "${google_compute_url_map.dev.self_link}"
}

// Create forwarding rule
resource "google_compute_global_forwarding_rule" "dev" {
  name       = "${var.service}-http-rule"
  target     = "${google_compute_target_http_proxy.dev.self_link}"
  port_range = "80"
}

// Autoscaler configuration
resource "google_compute_autoscaler" "dev" {
  name    = "${var.service}-autoscaler"
  target  = "${google_compute_instance_group_manager.dev.self_link}"

  autoscaling_policy {
    max_replicas    = 2  //10
    min_replicas    = 1
    cooldown_period = 60

    cpu_utilization {
      target = 0.6
    }
  }
}


// Create Google SQL Database Instance
resource "google_sql_database_instance" "dev" {
  name = "wordpress"
  database_version = "${var.sql_db}"
  region = "${var.region}"
  project                 = "${var.project_name}"
  settings {
    # Second-generation instance tiers are based on the machine
    # type. See argument reference below.
    tier = "db-f1-micro"
  }
}

// Create Google SQL Database User
resource "google_sql_user" "dev" {
  name     = "wordpress"
  instance = "${google_sql_database_instance.dev.name}"
  host     = "%"
  password = "password"
  project  = "${var.project_name}"  
}

// Create Google SQL Database
resource "google_sql_database" "dev" {
  name      = "wordpress"
  instance  = "${google_sql_database_instance.dev.name}"
  charset   = "utf8"
  project   = "${var.project_name}"  
}


// Terraform remote state
terraform {
   required_version = ">= 0.11.10"

    backend "gcs" {
        bucket  = "gvb-wordpress-terraform-remote-state"
        prefix  = "terraform/state"
		credentials = "~/.config/gcloud/wordpress-248302-e69b3701643e.json"
  }
}

