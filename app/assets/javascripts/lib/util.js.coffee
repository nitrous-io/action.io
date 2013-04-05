AIO.util =
  userAgent: new UAParser().getResult()

  IsMac:
    navigator.userAgent.indexOf("Macintosh") != -1

  mixpanel: (eventName, properties = {}) ->
    if mixpanel? && !AIO.get('router.applicationController.currentUser.admin')
      currentUser = AIO.get('router.applicationController.currentUser')

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
      currentUser = AIO.get 'router.applicationController.currentUser'
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
    if mixpanel? && !AIO.get('router.applicationController.currentUser.admin')
      mixpanel.people.increment(property, value)

  authenticateWithFirebase: ->
     firebaseMainRef = new Firebase(AIO.get('firebaseHost'));
     $.get('/firebase/auth_token').done (data) =>
       if data.auth_token?
         firebaseMainRef.auth data.auth_token, (error) =>
           if(!error)
             AIO.set 'firebaseAuthenticated', true

  generateFirepadRef: (documentPath) ->
    firebaseHost = AIO.get('firebaseHost')
    urlSlugs = [ firebaseHost ]

    router = AIO.get 'router'
    ideController = router.get 'ideController'
    box = ideController.get 'content'
    box_id = box.get('id') || 'global'

    urlSlugs.push 'box', box_id

    if documentPath && (absoluteDocumentPath = documentPath.get('absolutePath'))
      pathToken = window.btoa unescape(encodeURIComponent( absoluteDocumentPath ))
      urlSlugs.push 'pad', pathToken

    urlSlugs.join('/');

