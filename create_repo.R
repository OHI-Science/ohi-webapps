library(stringr)

country = 'American Samoa'
repo = sprintf('ohi-%s', tolower(str_replace_all(country,fixed(' '),'_')))
curl -u "$username:$token" https://api.github.com/user/repos -d '{"name":"'$repo_name'"}'

# read in token outside of repo, generated via https://help.github.com/articles/creating-an-access-token-for-command-line-use
token = scan('~/.github-token', 'character')

# check for repo existence
github_repo_exists = system(sprintf('git ls-remote git@github.com:ohi-science/%s.git', repo), ignore.stderr=T) != 128

if (!github_repo_exists){

  # create using Github API: https://developer.github.com/v3/repos/#create
  cmd = sprintf('curl -u "bbest:%s" https://api.github.com/orgs/ohi-science/repos -d \'{"name":"%s"}\'', token, repo)
  system(cmd)

}

# TODO: per repo
# touch README.md
# git init
# git add README.md
# git commit -m "first commit"
# git remote add origin https://github.com/OHI-Science/ohi-albania.git
# git push -u origin master