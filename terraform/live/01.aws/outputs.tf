output "acm_domain_validation_options" {
  value = aws_acm_certificate.cert.domain_validation_options
}

output "heartbeat_api_domain_name" {
  value = aws_apigatewayv2_domain_name.heartbeat.domain_name_configuration[0].target_domain_name

}
