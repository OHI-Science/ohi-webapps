library(shiny)
library(shinyapps)
library(stringr)

# vars
# TODO: read from csv with column run=T, and loop
repo        = 'ohi-israel'
scenario    = 'med2014' # sub2014 for initial global

# parameters
action     = 'deploy' # action=deploy|test-web|test-full
dir_root   = '~/github/ohi-webapps'
dir_shiny  = '~/github/ohicore/inst/shiny_app'
dir_data   = file.path('~/github', repo)
dir_app    = file.path('~/github/ohi-webapps', repo)
url_suffix = sprintf('%s-%s', str_replace(repo, '^ohi-', ''), scenario)

# create app dir to contain data and shiny files
setwd(dir_root)
dir.create(dir_app, showWarnings=F)
setwd(dir_app)

# copy data repo files
data_files = list.files(dir_data, recursive=T)
for (f in data_files){ # f = app_files[1]  
  dir.create(dirname(f), showWarnings=F, recursive=T)
  suppressWarnings(file.copy(file.path(dir_data, f), f, overwrite=T, recursive=T, copy.mode=T, copy.date=T))
}

# copy ohicore shiny app files
shiny_files = list.files(dir_shiny, recursive=T)
for (f in shiny_files){ # f = app_files[1]  
  dir.create(dirname(f), showWarnings=F, recursive=T)
  suppressWarnings(file.copy(file.path(dir_shiny, f), f, overwrite=T, recursive=T, copy.mode=T, copy.date=T))
}

# overwrite ui.R with ui_web.R
file.rename('server_web.R', 'server.R')
file.rename(    'ui_web.R', 'ui.R')

# write config
cat(sprintf('# configuration for application
dir_scenario: %s
debug: False
last_updated: %s
', scenario, Sys.Date()), file='app_config.yaml')

if (action == 'deploy'){
  # deploy to web
  deployApp(appDir=dir_app, appName=url_suffix, upload=T, launch.browser=F, lint=F)
  # publishes to http://ohi-science.shinyapps.io/[url_suffix]  
} else if (action == 'test-web') {
  # test locally, with just Data tab for web deployment
  suppressWarnings(rm('dir_scenario'))
  runApp()
} else if (action == 'test-full'){
  # test locally, with all tabs for desktop
  #devtools::load_all('~/github/ohicore')
  #devtools::install_github('ohi-science/ohicore')
  setwd('~/github/ohi-israel/med2014')
  require(methods)
  suppressWarnings(require(ohicore))
  launch_app()
} else {
  stop('Parameter action needs to be one of: deploy, test-web, test-full')
}


