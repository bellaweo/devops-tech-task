output "hello_world_hostname" {
  description = "hostname to access hello world app (hostname of the alb)"
  value       = aws_lb.self.dns_name
}

output "acmpca_root_ca" {
  description = "aws acm pca root ca certificate"
  value       = var.enable_ssl ? aws_acmpca_certificate_authority.fake[0].certificate : null
}
