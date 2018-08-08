resource "google_compute_instance" "default" {
  name         = "${var.name}"
  machine_type = "${var.machine_type}"
  zone         = "${var.zone}"

  tags = ["adagios", "nagios"]

  boot_disk {
    initialize_params {
      image = "${var.image}"
    }
  }

  network_interface {
    network = "default"

    access_config {
      // Ephemeral IP
    }
  }

  /* metadata { */
  /*   foo = "bar" */
  /* } */

  metadata_startup_script = "${file("${path.module}/files/init.sh")}"

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }
}
