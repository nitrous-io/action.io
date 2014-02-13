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
  coupon            : null
  gravatar_hash     : null
  user_profile      : null
  billing_profile   : null
  rewardable_invites_count : null
  private_snapshots_enabled: false

  # This weird naming because Rails expects
  # nested resource to be named as user_profile_attibutes
  user_profile_attributesBinding: 'user_profile'

  saving : null
  errors : null
  resetting_password : null

  hasCompany: false

  referralLinkFullURL: (->
    if path = @get 'referral_link'
      "#{location.protocol}//#{location.host}#{path}"
  ).property 'referral_link'

  referralLinkFullShareableURL: (->
    "#{@get 'referralLinkFullURL'}?utm_source=nitrous.io&utm_medium=copypaste&utm_campaign=referral"
  ).property 'referralLinkFullURL'

  referralLinkFullFacebookURL: (->
    "#{@get 'referralLinkFullURL'}?utm_source=nitrous.io&utm_medium=facebook&utm_campaign=referral"
  ).property 'referralLinkFullURL'

  referralLinkFullTwitterURL: (->
    "#{@get 'referralLinkFullURL'}?utm_source=nitrous.io&utm_medium=twitter&utm_campaign=referral"
  ).property 'referralLinkFullURL'

  referralLinkFullGooglePlusURL: (->
    "#{@get 'referralLinkFullURL'}?utm_source=nitrous.io&utm_medium=googleplus&utm_campaign=referral"
  ).property 'referralLinkFullURL'

  gravatarUrl: (->
    if gravatar_hash = @get 'gravatar_hash'
      "https://secure.gravatar.com/avatar/#{gravatar_hash}?s=45"
  ).property 'gravatar_hash'

  resourceName: 'user'
  resourceProperties: ['email', 'full_name', 'user_profile_attributes']

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

  resetPassword: ->
    @set 'resetting_password', true
    jQuery.ajax( url: '/users/password', dataType: 'json', type: 'POST', data: { user: { email: @email } } )
          .fail (e) =>
            if e.status == 422
              @set 'errors', $.parseJSON(e.responseText).errors
          .always =>
             @set 'resetting_password', false

  free_n2o: (-> # sorry no camelcase for consistency
    (@get('max_n2o') ? 0) - (@get('used_n2o') ? 0)
  ).property 'used_n2o', 'max_n2o'

  hasUsedN2O: (->
    @get('used_n2o') > 0
  ).property 'used_n2o'

  isGithubAuthenticated: (->
    _.any @get("authentications"), (authentication) ->
      authentication.provider == "github"
  ).property "authentications"

  isGoogleAuthenticated: (->
    _.any @get("authentications"), (authentication) ->
      authentication.provider == "google"
  ).property "authentications"

  isLinkedinAuthenticated: (->
    _.any @get("authentications"), (authentication) ->
      authentication.provider == "linkedin"
  ).property "authentications"

  isConfirmed: (->
    !!@get("confirmed_at")
  ).property "confirmed_at"

  snapshots: (->
    AIO.SnapshotsCollection.create
      content: _.filter AIO.get('router.snapshotsController').get('content'), (snapshot) =>
        @get('id') == snapshot.get('user_id')
  ).property 'AIO.router.snapshotsController.content'

  completedSnapshots: (->
    AIO.SnapshotsCollection.create
      content: _.filter AIO.get('router.snapshotsController').get('content'), (snapshot) =>
        @get('id') == snapshot.get('user_id') && snapshot.get('completed')
  ).property 'AIO.router.snapshotsController.content.@each.completed'

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

  fetchCompany: ->
    $.ajax(type: 'GET', dataType: 'json', url: '/user/company')
