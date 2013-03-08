AIO.IdeController = Em.ObjectController.extend
  needs: ['ideLayout', 'ideMainMenu', 'ideSidebar', 'ideEditor', 'ideConsole']
  sftpSocket: null

  initialize: (->
    if @get('content.state') == 'running'
      @set 'sftpSocket', sftpSocket = AIO.SftpSocket.create box: @get('content')

      @get('controllers.ideLayout').initialize()
      @get('controllers.ideMainMenu').initialize()
      @get('controllers.ideSidebar').initialize()
      @get('controllers.ideEditor').initialize()
      @get('controllers.ideConsole').initialize()

      sftpSocket.connect()

      # workaround for safari socket.io bug ----
      if AIO.get("environment") != "test"
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
  ).observes 'content'

  reset: ->
    if sftpSocket = @get 'sftpSocket'
      sftpSocket.disconnect()

    @get('controllers.ideLayout').reset()
    @get('controllers.ideMainMenu').reset()
    @get('controllers.ideSidebar').reset()
    @get('controllers.ideEditor').reset()
    @get('controllers.ideConsole').reset()

    @set 'sftpSocket', null
    @set 'content', null

  redirectToIndexWhenNotRunning: (->
    if state = @get('content.state')
      unless state == 'running'
        Em.run.next =>
          this.transitionToRoute 'boxes.index'
  ).observes 'content.state'
