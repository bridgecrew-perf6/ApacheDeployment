//for retriving default service account

data "google_compute_default_service_account" "default" {
}
output "default_service_account" {
  value = data.google_compute_default_service_account.default.email
}
resource "google_compute_network" "vpc_network1" {
  name                    = "private-net"
  auto_create_subnetworks ="false"
}
#creating custom subnetwork with enable vpc flow logs in specifies ip ranges
resource "google_compute_subnetwork" "vpc_subnetwork1" {
  name          = "subnet-public"
  network       = google_compute_network.vpc_network1.id
  region = "us-central1"
  ip_cidr_range = "10.1.0.0/24"
 depends_on = [
    google_compute_network.vpc_network1
  ]
}
resource "google_compute_subnetwork" "vpc_subnetwork2" {
  name          = "subnet-private"
  network       = google_compute_network.vpc_network1.id
  region = "us-central1"
  ip_cidr_range = "10.2.0.0/20"
 depends_on = [
    google_compute_network.vpc_network1
  ]
}
resource "google_compute_firewall" "allow_ssh_for_jumphost_rule" {
  name    = "jump-host-rule"
  network       = google_compute_network.vpc_network1.id
  target_tags = ["jump-host"]
  source_ranges = ["0.0.0.0/0"]
#allowing tcp protocol with required ports
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
   depends_on = [
    google_compute_network.vpc_network1
  ]
}
resource "google_compute_firewall" "allow_ssh_vm_rule" {
  name    = "private-vm-rule"
  network       = google_compute_network.vpc_network1.id
  target_tags = ["vm-tag"]
  source_tags = ["jump-host"]
#allowing tcp protocol with required ports
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
   depends_on = [
    google_compute_network.vpc_network1
  ]
}

resource "google_compute_instance" "instance1" {
  name         = "public-vm-bastian-host"
  zone         = "us-central1-a"
  machine_type = "f1-micro"
  boot_disk {
    initialize_params {
     image = "debian-cloud/debian-9"
    }
  }
  scheduling {
        preemptible = false
        automatic_restart = false
    }
  network_interface {
    network = google_compute_network.vpc_network1.id
    subnetwork = google_compute_subnetwork.vpc_subnetwork1.id
    access_config {
      # Allocate a one-to-one NAT IP to the instance
    }
  }

    #Apply the firewall rule to allow external IPs to access this instance
    tags = ["jump-host","http-server"]
  
}
/*
data "google_compute_default_service_account" "default" {
}
*/
#creating instance(creating apache tomcat server)
resource "google_compute_instance" "instance2" {
  name         = "private-vm"
  zone         = "us-central1-a"
  machine_type = "f1-micro"
  boot_disk {
    initialize_params {
     image = "debian-cloud/debian-9"
    }
  }
  scheduling {
        preemptible = false
        automatic_restart = false
    }
  network_interface {
    network = google_compute_network.vpc_network1.id
    subnetwork = google_compute_subnetwork.vpc_subnetwork2.id
  }
  #installing apache server
 #metadata_startup_script = "sudo apt-get update && sudo apt-get install apache2 -y && echo '<!doctype html><html><body><h1>Apache is running</h1></body></html>' | sudo tee /var/www/html/index.html

    #Apply the firewall rule to allow external IPs to access this instance
    tags = ["vm-tag","http-server"]
  
}
resource "google_storage_bucket" "bucket" {
  //bucket name unique
  name     = "server23769916"
  storage_class = "STANDARD"
  location = "us-central1"
  
  uniform_bucket_level_access = true
 
  
}
resource "google_storage_bucket_object" "object" {
  name   = "apacheindex"
  source = "C:/Users/THLOHITH/Downloads/apache-tomcat-8.5.75-windows-x64/apache-tomcat-8.5.75/webapps/docs/index.html"
  bucket = "${google_storage_bucket.bucket.name}"
}

resource "google_compute_router" "router" {
  name    = "my-router"
  region  = google_compute_subnetwork.vpc_subnetwork2.region
  network       = google_compute_network.vpc_network1.id
  bgp {
    asn               = 64514
    advertise_mode    = "CUSTOM"
    advertised_groups = ["ALL_SUBNETS"]
  }
}
resource "google_compute_router_nat" "private-nat" {
  name                               = "my-router-nat"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
 }
