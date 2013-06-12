AIO.Invite = AIO.Resource.extend
  email      : null
  state      : null
  created_at : null
  error      : null

  resourceUrl: '/invites'
  resourceName : 'invite'
  resourceProperties: ['email']

  prettified_state: (->
    switch state = @get 'state'
      when 'activated'
        'sent'
      when 'accepted'
        '✓ accepted'
      else
        state
  ).property 'state'

  validations:
    email: (v) -> "can't be blank" unless v && v.length > 0
