shinyServer(function(input, output) {
  
  output$git_commit = renderText({    
    git2r::pull(repo)
    h = git2r::commits(repo)[[1]]
    return(sprintf('[%s] %s: %s', substr(h@sha, 1, 7), git2r::when(h), h@summary))
  })
  
  output$text <- renderText({ paste(list.files(), collapse='<br>\n') })
  
})