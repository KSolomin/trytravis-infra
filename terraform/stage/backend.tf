terraform {
  backend "gcs" {
    bucket = "states-of-terraform"
    prefix = "stage"
  }
}
