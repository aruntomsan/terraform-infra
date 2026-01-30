output "dependency_confirmed" {
  description = "dummy"
  value       = module.vpc.natgw_ids[0]
}