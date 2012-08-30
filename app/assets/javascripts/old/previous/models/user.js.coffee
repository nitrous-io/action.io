class aio.models.User extends Backbone.Model
  hasGitHub: ->
    if authentications = this.get('authentications')
      for authentication in authentications
        return true if authentication.provider == 'github'
    false
