AIO.util =
  userAgent: new UAParser().getResult()

  IsMac:
    navigator.userAgent.indexOf("Macintosh") != -1

  mixpanel: (eventName, properties = {}) ->
    if mixpanel?
      p =
        username: AIO.get('router.applicationController.currentUser.username')
        os_name: @userAgent.os.name
        os_version: @userAgent.os.version
        browser_name: @userAgent.browser.name
        browser_version: @userAgent.browser.version
        browser_major: @userAgent.browser.major

      mixpanel.track eventName, _.defaults(properties, p)

  mixpanelIdentifyUser: ->
    if mixpanel?
      currentUser = AIO.get 'router.applicationController.currentUser'
      currentUserFullName = currentUser.get 'full_name'

      mixpanel.identify currentUser.get('email')
      mixpanel.people.set
        $email: currentUser.get('email')
        $username: currentUser.get('username')
        $created: currentUser.get('created_at')
        $name: currentUserFullName
        $first_name: currentUserFullName?.split(' ')[0]
        $last_name: currentUserFullName?.split(' ').slice -1
        is_github_authenticated: currentUser.get('isGithubAuthenticated')

  mixpanelIncrement: (property, value=1) ->
    if mixpanel?
      mixpanel.people.increment(property, value)
