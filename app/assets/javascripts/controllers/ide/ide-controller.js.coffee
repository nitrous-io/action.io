App.IdeController = Em.ObjectController.extend
  sftpSocket: null
  partsSocket: null
  sftpSocketReady: null
  sftpTimeoutAlert: null

  repository: null

  sftpConnectionGracePeriod: 5 * 1000 # TODO: This should come from a KeyValue object from the server-side
  sftpConnectionLost: false

  sftpSocketReadyBinding: Em.Binding.oneWay 'sftpSocket.started'

  initialize: (->
    if content = @get 'content'
      @set 'sftpSocket', sftpSocket = App.SftpSocket.create box: content
      @set 'partsSocket', partsSocket = App.PartsSocket.create box: content

      router = App.get 'router'
      router.get('ideLayoutController').initialize()
      router.get('ideMainMenuController').initialize()
      router.get('ideSidebarController').initialize()
      router.get('ideEditorController').initialize()
      router.get('ideConsoleController').initialize()
      router.get('ideCollaborationPaneController').initialize()

      sftpSocket.connect()
      partsSocket.connect()
  ).observes 'content'

  sftpSocketDisconnected: (->
    unless @get('sftpSocketReady')
      sftpTimeoutAlert = Em.run.later this, (->
        @set 'sftpConnectionLost', true
      ), @get('sftpConnectionGracePeriod')

      @set 'sftpTimeoutAlert', sftpTimeoutAlert
  ).observes 'sftpSocketReady'

  sftpSocketConnected: (->
    if @get('sftpSocketReady') && (sftpTimeoutAlert = @get('sftpTimeoutAlert'))
      Em.run.cancel sftpTimeoutAlert
      @set 'sftpConnectionLost', false

      if repo = @get 'repository'
        if repo.get('state') == 'failed'
          cacheKey = "repo:#{repo.get('id')}:shownError"
          if !App.localStorage.get(cacheKey)
            App.set 'flashMessage', { type: 'error', text: "Cloning the repository failed: #{repo.get('failure_reason')}", sticky: true }
            App.localStorage.set(cacheKey, true)
  ).observes 'sftpSocketReady'

  reset: ->
    if sftpSocket = @get 'sftpSocket'
      sftpSocket.disconnect()

    if partsSocket = @get 'partsSocket'
      partsSocket.disconnect()

    router = App.get 'router'
    router.get('ideLayoutController').reset()
    router.get('ideMainMenuController').reset()
    router.get('ideConsoleController').reset()
    router.get('ideEditorController').reset()
    router.get('ideSidebarController').reset()
    router.get('ideCollaborationPaneController').reset()
    router.get('ideAutopartsController').reset()

    @set 'sftpSocket', null
    @set 'content', null

  redirectToIndexWhenNotRunning: (->
    if content = @get 'content'
      unless content.get('state') == 'running'
        Em.run.next ->
          App.get('router').transitionTo 'boxes.index'
  ).observes 'content.state'

  warnWhenOffline: (->
    if App.get 'offline'
      App.set 'flashMessage', { type: 'alert-error', text: "Unable to connect to the server. Changes will not be saved.", sticky: true }
    else
      App.set 'flashMessage', null
  ).observes 'App.offline'
