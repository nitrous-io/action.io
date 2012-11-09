AIO.IdeController = Em.ObjectController.extend
  sftpSocket: null

  initialize: (->
    if content = @get 'content'
      @set 'sftpSocket', sftpSocket = AIO.SftpSocket.create box: content

      router = AIO.get 'router'
      router.get('ideLayoutController').initialize()
      router.get('ideMainMenuController').initialize()
      router.get('ideSidebarController').initialize()
      router.get('ideEditorController').initialize()
      router.get('ideConsoleController').initialize()

      sftpSocket.connect()

      # workaround for safari socket.io bug ----
      socket = sftpSocket.get 'socket'
      socketURI = sftpSocket.get 'socketURI'
      window.setTimeout(->
        if !socket.socket.connecting && !socket.socket.connected && window.WebSocket
          tempWs = new WebSocket socketURI.replace 'https', 'wss'
          window.setTimeout(->
            io.sockets = {}
            sftpSocket.set 'socket', null
            sftpSocket.connect()
          , 2000)
      , 2000)
      # ----
    else
      this.reset()
  ).observes 'content'

  reset: ->
    if sftpSocket = @get 'sftpSocket'
      sftpSocket.disconnect()

    router = AIO.get 'router'
    router.get('ideLayoutController').reset()
    router.get('ideMainMenuController').reset()
    router.get('ideConsoleController').reset()
    router.get('ideEditorController').reset()
    router.get('ideSidebarController').reset()

    @set 'sftpSocket', null
    @set 'content', null

  redirectToIndexWhenNotRunning: (->
    if content = @get 'content'
      unless content.get('state') == 'running'
        Em.run.next ->
          AIO.get('router').transitionTo 'boxes.index'
  ).observes 'content.state'

