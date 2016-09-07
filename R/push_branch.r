## push_branch

push_branch <- function(branch, current_msg){ 
  
  # working locally (not from server), gh_token set in create_init.R, repo_name set in create_init_sc.Rs
  system(sprintf('git add -A; git commit -a -m " %s" ', current_msg))
  system(sprintf('git push https://%s@github.com/%s.git HEAD:%s', gh_token, git_slug, branch))
  
}