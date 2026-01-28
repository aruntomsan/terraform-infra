output "ecr_repository_urls" {
  description = "Map of repository names to their URLs"
  # We loop through the module instances created by for_each
  value       = { for k, v in module.ecr : k => v.repository_url }
}