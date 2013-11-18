AIO.PartsSocket = AIO.BaseSocket.extend
  name: 'parts'

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

  list: (callback) ->
    this.send 'list', callback

  search: (term, callback) ->
    this.send 'search', term, callback

  listAll: (callback) ->
    this.send 'listAll', callback

  install: (part, callback) ->
    this.send 'install', part, callback

  uninstall: (part, callback) ->
    this.send 'uninstall', part, callback
