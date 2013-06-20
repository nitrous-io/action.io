AIO.User = AIO.Resource.extend
  username          : null
  email             : null
  full_name         : null
  authentications   : null
  created_at        : null
  admin             : null
  actions           : null
  max_n2o           : 0
  used_n2o          : 0
  intro_seen        : false
  referral_link     : null

  referralLinkFullURL: (->
    if path = @get 'referral_link'
      "#{location.protocol}//#{location.host}#{path}"
  ).property 'referral_link'

  resourceName: 'user'

  free_n2o: (-> # sorry no camelcase for consistency
    (@get('max_n2o') ? 0) - (@get('used_n2o') ? 0)
  ).property 'used_n2o', 'max_n2o'

  isGithubAuthenticated: (->
    _.any @get "authentications", (authentication) ->
      authentication.provider == "github"
  ).property "authentications"

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
