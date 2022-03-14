
#creating instance(creating apache tomcat server)
resource "google_compute_instance" "instance" {
  name         = "apache-server"
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
    network = "default"
    access_config {
      # Allocate a one-to-one NAT IP to the instance
    }
  }
  #installing apache server
  metadata_startup_script = "sudo apt-get update && sudo apt-get install apache2 -y && echo '<!doctype html><html><body><h1>Apache is running</h1></body></html>' | sudo tee /var/www/html/index.html"

    //Apply the firewall rule to allow external IPs to access this instance
    //If you specfiy both firewall tags like http-server and https-server, then for external ip address have to use http://external ip address
    #tags=["http-server","https-server"]
    //If you specfiy http-server, then for external ip address have to use https://external ip address
    tags = ["http-server"]
    //If you specfiy https-server, then for external ip address have to use http://external ip address
    #tags = ["http-server"]
  
}