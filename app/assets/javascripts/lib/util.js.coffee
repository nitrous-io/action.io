AIO.util =
  userAgent: new UAParser().getResult()

  IsMac:
    navigator.userAgent.indexOf("Macintosh") != -1

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

      mixpanel.identify currentUser.get('email')
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
