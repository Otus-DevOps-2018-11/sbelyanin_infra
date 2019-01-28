terraform {
  backend "gcs" {
    bucket = "bucket-reddit"
    prefix = "terraform/prod"
  }
}
