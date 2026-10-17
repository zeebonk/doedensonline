output "dev_ip" {
  description = "Dev server public IPv4"
  value       = hcloud_server.doedensonline.ipv4_address
}
