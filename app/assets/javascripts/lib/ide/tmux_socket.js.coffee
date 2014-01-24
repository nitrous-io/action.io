AIO.TmuxSocket = AIO.BaseSocket.extend
  name: 'tmux'

  serverURIBinding: 'box.box_server_uri'
  serverName: 'rainbow'

  didConnect: ->
    @_super()
    boxId = @get 'box.id'
    socket = @get 'socket'

    socket.send 'start', boxId, =>
      @set 'started', true
      @set('startedFirstTime', true) if !@get('startedFirstTime')

  didClose: ->
    @_super()
    @set 'started', false

  disconnect: ->
    @_super()
    @setProperties
      startedFirstTime: false
      started: false
      box: null

  createSession: (callback) ->
    this.send 'createSession', callback

  createWindow: (windowId) ->
    this.send 'createWindow', windowId

  selectWindow: (windowId) ->
    this.send 'selectWindow', windowId

  removeWindow: (windowId) ->
    this.send 'removeWindow', windowId
