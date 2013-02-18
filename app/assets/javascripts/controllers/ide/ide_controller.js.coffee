AIO.IdeController = Em.ObjectController.extend
  needs: ['boxes', 'ideLayout', 'ideMainMenu', 'ideSidebar', 'ideEditor', 'ideConsole']
  sftpSocket: null

  findById: (id) ->
    @get('controllers.boxes').findResource id, (box) =>
      console.log "setting content", box
      @set 'content', box

  initialize: (->
    if @get('content') && @get('content').constructor == AIO.Box
      @set 'sftpSocket', sftpSocket = AIO.SftpSocket.create box: @get('content')

      @get('controllers.ideLayout').initialize()
      @get('controllers.ideMainMenu').initialize()
      @get('controllers.ideSidebar').initialize()
      @get('controllers.ideEditor').initialize()
      @get('controllers.ideConsole').initialize()

      sftpSocket.connect()

      # workaround for safari socket.io bug ----
      #if AIO.get("environment") != "test"
        #socket = sftpSocket.get 'socket'
        #socketURI = sftpSocket.get 'socketURI'
        #window.setTimeout(->
        #  if !socket.socket.connecting && !socket.socket.connected && window.WebSocket
        #    tempWs = new WebSocket socketURI.replace 'https', 'wss'
        #    window.setTimeout(->
        #      io.sockets = {}
        #      sftpSocket.set 'socket', null
        #      sftpSocket.connect()
        #    , 2000)
        #, 2000)
      # ----
    #else
    #this.reset()
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
    if @get('content') && @get('content').constructor == AIO.Box
      unless @get('content').get('state') == 'running'
        Em.run.next ->
          this.transitionToRoute 'boxes.index'
  ).observes 'content.state'
