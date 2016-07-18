# unpopulate_layers_conf.r

unpopulate_layers_conf <- function(key=key, dir_repos=dir_repos, dir_repo=dir_repo, 
                                   git_url=git_url, default_scenario=default_scenario) {
  
  ## clone repo and remotes
  clone_repo(dir_repos, dir_repo, git_url)
  
  ## delete layers folder
  to_delete = paste(default_scenario, 
                    c('layers', 'layers.csv', 'conf', 'scores.csv',
                      'layers-empty_swapping-global-mean.csv',
                      'install_ohicore.r', 'calculate_scores.r', 
                      'launch_app_code.r', 'session.txt'), sep = '/')
  
  unlink(to_delete, recursive = TRUE, force = TRUE)
  
}