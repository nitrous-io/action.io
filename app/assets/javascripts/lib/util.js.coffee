AIO.util =
  userAgent: new UAParser().getResult()

  IsMac:
    navigator.userAgent.indexOf("Macintosh") != -1

  IsMobile:
    navigator.userAgent.match(/(Android|iPad|iPhone)/) != null

  mixpanel: (eventName, properties = {}) ->
    currentUser = AIO.get 'currentUser'
    if mixpanel? && !currentUser.get('admin')
      p =
        username:         currentUser.get('username')
        email:            currentUser.get('email')
        distinct_id:      currentUser.get('email')
        os_name:          @userAgent.os.name
        os_version:       @userAgent.os.version
        browser_name:     @userAgent.browser.name
        browser_version:  @userAgent.browser.version
        browser_major:    @userAgent.browser.major

      mixpanel.track eventName, _.defaults(properties, p)

  mixpanelIdentifyUser: ->
    if mixpanel?
      currentUser = AIO.get 'currentUser'
      currentUserFullName = currentUser.get('full_name')

      mixpanel.alias currentUser.get('email')

      personHash =
        $email: currentUser.get('email')
        $username: currentUser.get('username')
        $created: currentUser.get('created_at')
        $name: currentUserFullName
        is_github_authenticated: currentUser.get('isGithubAuthenticated')

      if currentUserFullName?
        splitName = currentUserFullName.split(' ')
        personHash.$first_name = splitName[0]
        personHash.$last_name  = splitName.slice(-1)[0]

      mixpanel.people.set personHash

  mixpanelIncrement: (property, value=1) ->
    if mixpanel? && !AIO.get('currentUser.admin')
      mixpanel.people.increment(property, value)

  # Algo stolen from http://ejohn.org/files/pretty.js
  humanizedTimeProperty: (property) ->
    return (->
      # Assume property is in UTC
      date = new Date((@get property || "").replace(/-/g,"/").replace(/[TZ]/g," "))
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
    ).property(property)

  randomElement: (array) ->
    array[Math.floor(Math.random() * array.length)]

  randomBoxName: ->
    names = [
      'winterfell'
      'white-harbor'
      'pyke'
      'riverrun'
      'harrenhal'
      'eyrie'
      'casterly-rock'
      'lannisport'
      'kings-landing'
      'kingswood'
      'blackwater-bay'
      'dragonstone'
      'highgarden'
      'storms-end'
    ]
    this.randomElement(names)
