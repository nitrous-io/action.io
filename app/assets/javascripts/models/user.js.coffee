AIO.User = AIO.Resource.extend
  username          : null
  email             : null
  full_name         : null
  authentications   : null
  created_at        : null
  confirmed_at      : null
  admin             : null
  actions           : null
  max_n2o           : 0
  used_n2o          : 0
  intro_seen        : false
  referral_link     : null
  gravatar_hash     : null
  rewardable_invites_count : null

  current_password      : null
  password              : null
  password_confirmation : null

  saving : null
  errors : null

  referralLinkFullURL: (->
    if path = @get 'referral_link'
      "#{location.protocol}//#{location.host}#{path}"
  ).property 'referral_link'

  gravatarUrl: (->
    if gravatar_hash = @get 'gravatar_hash'
      "http://www.gravatar.com/avatar/#{gravatar_hash}"
  ).property 'gravatar_hash'

  resourceName: 'user'
  resourceProperties: ['email', 'full_name', 'password', 'password_confirmation', 'current_password']

  updateInfo: ->
    @set 'saving', true
    jQuery.ajax( url: '/users', dataType: 'json', type: 'PUT', data: this.serialize() )
          .done (json) =>
            if json && json.user
              this.deserialize(json.user)
          .fail (e) =>
            if e.status == 422
              @set 'errors', $.parseJSON(e.responseText).errors
          .always =>
            @set 'saving', false

  free_n2o: (-> # sorry no camelcase for consistency
    (@get('max_n2o') ? 0) - (@get('used_n2o') ? 0)
  ).property 'used_n2o', 'max_n2o'

  isGithubAuthenticated: (->
    _.any @get "authentications", (authentication) ->
      authentication.provider == "github"
  ).property "authentications"

  isConfirmed: (->
    !!@get("confirmed_at")
  ).property "confirmed_at"

  fetchN2O: ->
    $.ajax(
      type: 'GET'
      dataType: 'json'
      url: '/n2o'
    ).done (json) =>
      if maxN2O = json.n2o.max
        @set 'max_n2o', maxN2O
      if usedN2O = json.n2o.used
        @set 'used_n2o', usedN2O
