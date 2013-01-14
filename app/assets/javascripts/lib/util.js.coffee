AIO.util =
  userAgent: new UAParser().getResult()

  IsMac:
    navigator.userAgent.indexOf("Macintosh") != -1

  mixpanel: (eventName, properties = {}) ->
    if mixpanel?
      p =
        username: AIO.get('router.applicationController.currentUser.username')
        osName: @userAgent.os.name
        osVersion: @userAgent.os.version
        browserName: @userAgent.browser.name
        browserVersion: @userAgent.browser.version
        browserMajor: @userAgent.browser.major

      mixpanel.track eventName, _.defaults(properties, p)

  mixpanelIdentifyUser: ->
    if mixpanel?
      currentUser = AIO.get 'router.applicationController.currentUser'

      mixpanel.identify currentUser.get('email')
      mixpanel.people.set
        $email: currentUser.get('email')
        $username: currentUser.get('username')
        $created: currentUser.get('created_at')
        $name: currentUser.get('full_name')
        is_github_authenticated: currentUser.get('isGithubAuthenticated')

  mixpanelIncrement: (property, value=1) ->
    if mixpanel?
      mixpanel.people.increment(property, value)
