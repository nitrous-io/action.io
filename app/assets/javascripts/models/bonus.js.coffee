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
    'twitter_follow'
    'tweet_sent'
    'upgrade_account'
    'business_survey'
  ]

klass.properties.forEach (property) ->
  props = {}
  props[property] = null
  klass.reopen(props)
