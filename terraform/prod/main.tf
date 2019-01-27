provider "google" {
  version = "1.4.0"
  project = "${var.project}"
  region  = "${var.region}"
}

module "app" {
  source           = "../modules/app"
  public_key_path  = "${var.public_key_path}"
  private_key_path = "${var.private_key_path}"
  node_count       = "${var.node_count}"
  region           = "${var.region}"
  zone             = "${var.zone}"
  app_disk_image   = "${var.app_disk_image}"
  db_internal_ip   = "${module.db.db_internal_ip}"
}

module "db" {
  source           = "../modules/db"
  public_key_path  = "${var.public_key_path}"
  private_key_path = "${var.private_key_path}"
  node_count       = "${var.node_count}"
  region           = "${var.region}"
  zone             = "${var.zone}"
  db_disk_image    = "${var.db_disk_image}"
}

module "vps" {
  source        = "../modules/vps"
  source_ranges = ["${var.source_ranges_prod}"]
}
