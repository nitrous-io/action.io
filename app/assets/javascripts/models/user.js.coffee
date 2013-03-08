AIO.User = AIO.Model.extend
  username          : null
  email             : null
  full_name         : null
  available_invites : null
  created_at        : null
  admin             : null
  authentications   : null

  resourceName: 'user'

  isGithubAuthenticated: (->
    _.any @get "authentications", (authentication) ->
      authentication.provider == "github"
  ).property "authentications"

  isAbleToInvite: (->
    @get("available_invites") > 0
  ).property "available_invites"
