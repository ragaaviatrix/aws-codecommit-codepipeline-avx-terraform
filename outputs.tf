output "repo_username" {
  value = module.create_repo.creds_username
}

output "repo_user_password" {
  value = module.create_repo.creds_password
}

output "repo_clone_url" {
  value = module.create_repo.https_clone_url
}