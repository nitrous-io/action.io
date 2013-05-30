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
  sign_in_count     : null
  hide_boxes_tour   : null
  hide_ide_tour     : null

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

  hideTour: (tour) ->
    if tour
      $.ajax
        type: 'POST'
        dataType: 'json'
        url: "/app/hide_#{tour}_tour"

  shouldHideTour: (tour) ->
    switch tour
      when 'boxes'
        @get 'hide_boxes_tour'
      when 'ide'
        @get 'hide_ide_tour'
      else
        true
