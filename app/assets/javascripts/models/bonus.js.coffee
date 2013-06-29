klass = AIO.Bonus = AIO.Resource.extend
  resourceUrl: '/bonus'
  resourceName: 'bonus'

klass.reopenClass
  properties: [
    'invite_friends'
    'github'
    'twitter'
    'facebook'
    'linkedin'
    'google'
    'accepted_invite'
    'chrome_app'
  ]

klass.properties.forEach (property) ->
  props = {}
  props[property] = null
  klass.reopen(props)
