AIO.User = AIO.Model.extend
  username         : DS.attr('string')
  email            : DS.attr('string')
  fullName         : DS.attr('string')
  availableInvites : DS.attr('number')
  createdAt        : DS.attr('date')
  admin            : DS.attr('boolean')
  authentications  : null

  isGithubAuthenticated: (->
    _.any @get "authentications", (authentication) ->
      authentication.provider == "github"
  ).property "authentications"

  isAbleToInvite: (->
    @get("available_invites") > 0
  ).property "available_invites"
