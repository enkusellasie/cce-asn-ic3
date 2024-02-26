output "external_ip" {
  description = "The external IPv4 assigned to the global fowarding rule of the load balancer."
  value       = module.lb-http.external_ip
}
