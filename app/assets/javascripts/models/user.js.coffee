AIO.User = AIO.Resource.extend
  username        : null
  email           : null
  full_name       : null
  authentications : null

  resourceName: 'user'

  isGithubAuthenticated: (->
    _.any @get "authentications", (authentication) ->
      authentication.provider == "github"
  ).property "authentications"



