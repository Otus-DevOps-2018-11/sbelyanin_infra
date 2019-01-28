resource "google_compute_instance" "db" {
  name         = "reddit-db-${count.index}"
  count        = "${var.node_count}"
  machine_type = "g1-small"
  zone         = "${var.region}-${var.zone}"

  boot_disk {
    initialize_params {
      image = "${var.db_disk_image}"
    }
  }

  tags = ["reddit-db"]

  metadata {
    ssh-keys = "appuser:${file(var.public_key_path)}"
  }

  network_interface {
    network       = "default"
    access_config = {}
  }

  connection {
    type        = "ssh"
    user        = "appuser"
    agent       = false
    private_key = "${file(var.private_key_path)}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf",
      "sudo systemctl restart mongod",
    ]
  }
}

resource "google_compute_firewall" "firewall_mongo" {
  name    = "allow-mongo-default"
  network = "default"

  allow {
    protocol = "tcp"

    ports = ["21017"]
  }

  source_tags = ["reddit-app"]
  target_tags = ["reddit-db"]
}
