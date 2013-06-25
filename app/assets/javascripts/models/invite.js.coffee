AIO.Invite = AIO.Resource.extend
  email      : null
  state      : null
  created_at : null
  error      : null
  n2o_earned : null

  resourceUrl: '/invites'
  resourceName : 'invite'
  resourceProperties: ['email']

  humanizedState: (->
    switch state = @get 'state'
      when 'activated'
        "sent"
      else
        state
  ).property 'state'

  humanizedN2oEarned: (->
    if n2o_earned = @get 'n2o_earned'
      "+#{n2o_earned}"
    else
      ""
  ).property 'n2o_earned'

  humanizedCreatedAt: AIO.util.humanizedTimeProperty('created_at')

  validations:
    email: (v) -> "can't be blank" unless v && v.length > 0
