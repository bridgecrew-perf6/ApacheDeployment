provider "google"{
    credentials="${file("${var.path}/apachedeploy.json")}"
    project=var.project
    region="us-central1"
}