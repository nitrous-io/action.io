AIO.Invite = AIO.Resource.extend
  email      : null
  state      : null
  created_at : null
  error      : null

  resourceUrl: '/invites'
  resourceName : 'invite'
  resourceProperties: ['email']

  humanizedState: (->
    switch state = @get 'state'
      when 'activated'
        'sent'
      when 'accepted'
        '✓ accepted'
      else
        state
  ).property 'state'

  # Algo stolen from http://ejohn.org/files/pretty.js
  humanizedCreatedAt: (->
    # Assume created_at is UTC
    date = new Date((@get 'created_at' || "").replace(/-/g,"/").replace(/[TZ]/g," "))
    # Get now in UTC as well
    now = new Date(new Date().toISOString().replace(/-/g,"/").replace(/[TZ]/g," "))

    diff = (now.getTime() - date.getTime()) / 1000
    day_diff = Math.floor(diff / 86400)

    if isNaN(day_diff) || day_diff < 0
      return

    day_diff == 0 && (
              diff < 60 && "just now" ||
              diff < 120 && "a minute ago" ||
              diff < 3600 && Math.floor( diff / 60 ) + " minutes ago" ||
              diff < 7200 && "an hour ago" ||
              diff < 86400 && Math.floor( diff / 3600 ) + " hours ago") ||
              day_diff == 1 && "yesterday" ||
              day_diff < 7 && day_diff + " days ago" ||
              day_diff < 31 && Math.ceil( day_diff / 7 ) + " weeks ago" ||
              day_diff < 365 && Math.floor( day_diff / 30 ) + " months ago" ||
              day_diff < 730 && "last year" ||
              Math.floor( day_diff / 365 ) + " years ago"

  ).property 'created_at'

  validations:
    email: (v) -> "can't be blank" unless v && v.length > 0
