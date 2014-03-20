AIO.MuxSocket = AIO.BaseSocket.extend
  name: 'mux'
  box: null
  started: false
  startedFirstTime: false

  serverURIBinding: 'box.box_server_uri'
  serverName: 'rainbow'

  didConnect: ->
    @_super()
    boxId = @get 'box.id'
    socket = @get 'socket'

    socket.send 'start', boxId, =>
      @set 'started', true
      @set('startedFirstTime', true) if !@get('startedFirstTime')

    socket.on 'mux', (data) ->
      ideConsoleController = AIO.get 'router.ideConsoleController'
      switch data.event
        when "new_client"
          ideConsoleController.createTabWithId {}, data.sessionId
        when "resize"
          # retrigger the event
          ideConsoleController.trigger "resize", data

  didClose: ->
    @_super()
    @set 'started', false

  disconnect: ->
    @_super()
    @setProperties
      startedFirstTime: false
      started: false
      box: null
