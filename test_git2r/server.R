shinyServer(function(input, output) {
  
  output$git_commit = renderText({    
    pull(repo)
    h = commits(repo)[[1]]
    return(sprintf('[%s] %s: %s', substr(h@sha, 1, 7), when(h), h@summary))
  })
  
  output$text <- renderText({ paste(list.files('ohi-israel'), collapse='<br>\n') })
  
})