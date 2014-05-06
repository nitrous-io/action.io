# Overrides sections of BaseSocket to support multiple namespaces within a single
# socket.  PartsSocket should eventually be moved into here.

App.CommandSocket = App.BaseSocket.extend
  name: 'command'
  additionalNamespaces: ['search']

  serverURIBinding: 'box.box_server_uri'
  serverName: 'rainbow'

  resultDocument: null

  connect: ->
    @_super()
    _.each this.additionalNamespaces, (namespace) =>
      @connection.on namespace, (action, args) =>
        @socket.emit [namespace, action].join('.'), args...

  didConnect: ->
    @_super()
    boxId = @get 'box.id'
    socket = @get 'socket'

    socket.send 'start', boxId, =>
      @set 'started', true

    socket.on 'search.commandOutput', (data) =>
      console.log("Command out: #{data}")
      if doc = @get('resultDocument')
        doc.set('content', doc.get('content') + data)

    socket.on 'search.commandError', (data) ->
      console.log("Command error: #{data}")

    socket.on 'search.commandComplete', (code) ->
      console.log("Whoops: #{code}")

  didClose: ->
    @_super()
    @set 'started', false

  disconnect: ->
    if connection = @get 'connection'
      connection.destroy()
    @didClose()
    @setProperties
      socket: null
      connection: null

  _didAuthenticate: ->
    @_super()
    if socket = @get('socket')
      _.each this.additionalNamespaces, (namespace) =>
        socket.sendAs namespace, 'init', -> {}

  sendAs: ->
    if socket = @get 'socket'
      socket.sendAs _.toArray(arguments)...

  search: (term, path, callback) ->
    this.sendAs 'search', 'search', term, path, =>
      editorController = App.get('router.ideEditorController')
      termTitle = if term.length > 6 then term.slice(0, 6) + "..." else term
      doc = editorController.createTab
        content: "Searching...\n\n"
        path:
          name: "Search results: '#{termTitle}'" # used for tab title
        contentType: 'searchresult'
      @set('resultDocument', doc)

