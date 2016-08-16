# unpopulate_layers_conf.r

unpopulate_layers_conf <- function(key, dir_repos, dir_repo, 
                                   git_url, default_scenario) {
  
  ## JSL Aug 15 you don't want this happening here
  # ## clone repo and remotes
  # clone_repo(dir_repos, dir_repo, git_url)
  # 
  ## delete all the things
  to_delete <- paste(dir_repo, default_scenario, 
                    c('layers', 'layers.csv', 'conf', 'scores.csv',
                      'layers-empty_swapping-global-mean.csv',
                      'install_ohicore.r', 'calculate_scores.r', 'configure_toolbox.r', 
                      'launch_app_code.r', 'session.txt'), sep = '/')
  
  cat(sprintf(' Deleting contents of repo, including /layers and /conf folders... '))
  
  unlink(to_delete, recursive = TRUE, force = TRUE)
  
}