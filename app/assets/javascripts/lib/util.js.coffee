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

