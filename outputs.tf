output "HashiCat_URL" {
  value = "http://${alicloud_instance.hashicat-instance.public_ip}"
}