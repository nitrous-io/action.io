AIO.User = AIO.Resource.extend
  username          : null
  email             : null
  full_name         : null
  authentications   : null
  available_invites : null
  created_at        : null
  admin             : null
  actions           : null
  activated         : null

  resourceName: 'user'

  isGithubAuthenticated: (->
    _.any @get "authentications", (authentication) ->
      authentication.provider == "github"
  ).property "authentications"

  isActivated: (->
    @get('activated')
  ).property 'activated'

  isAbleToInvite: (->
    @get("available_invites") > 0
  ).property "available_invites"

  canCreateBox: (->
    @get("actions.create_box")
  ).property "actions"
