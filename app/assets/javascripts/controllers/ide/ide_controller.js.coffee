AIO.IdeController = Em.ObjectController.extend
  sftpSocket:                 null
  partsSocket:                null
  muxSocket:                  null

  sftpSocketReady:            null
  sftpTimeoutAlert:           null

  sftpConnectionGracePeriod:  5 * 1000 # TODO: This should come from a KeyValue object from the server-side
  sftpConnectionLost:         false

  sftpSocketReadyBinding:     Em.Binding.oneWay 'sftpSocket.started'

  initialize: (->
    if content = @get 'content'
      @set 'sftpSocket', sftpSocket = AIO.SftpSocket.create box: content
      @set 'partsSocket', partsSocket = AIO.PartsSocket.create box: content
      @set 'muxSocket', muxSocket = AIO.MuxSocket.create box: content

      router = AIO.get 'router'
      router.get('ideLayoutController').initialize()
      router.get('ideMainMenuController').initialize()
      router.get('ideSidebarController').initialize()
      router.get('ideEditorController').initialize()
      router.get('ideConsoleController').initialize()
      router.get('ideCollaborationPaneController').initialize()

      sftpSocket.connect()
      partsSocket.connect()
      muxSocket.connect()
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
  ).observes 'sftpSocketReady'

  reset: ->
    if sftpSocket = @get 'sftpSocket'
      sftpSocket.disconnect()

    if partsSocket = @get 'partsSocket'
      partsSocket.disconnect()

    if muxSocket = @get 'muxSocket'
      muxSocket.disconnect()

    router = AIO.get 'router'
    router.get('ideLayoutController').reset()
    router.get('ideMainMenuController').reset()
    router.get('ideConsoleController').reset()
    router.get('ideEditorController').reset()
    router.get('ideSidebarController').reset()
    router.get('ideCollaborationPaneController').reset()
    router.get('ideAutopartsController').reset()

    @set 'sftpSocket', null
    @set 'muxSocket', null
    @set 'content', null

  redirectToIndexWhenNotRunning: (->
    if content = @get 'content'
      unless content.get('state') == 'running'
        Em.run.next ->
          AIO.get('router').transitionTo 'boxes.index'
  ).observes 'content.state'

  warnWhenOffline: (->
    if AIO.get 'offline'
      AIO.set 'flashMessage', { type: 'alert-error', text: "Unable to connect to the server. Changes will not be saved.", sticky: true }
    else
      AIO.set 'flashMessage', null
  ).observes 'AIO.offline'
