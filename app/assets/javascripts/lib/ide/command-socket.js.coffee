# Overrides sections of BaseSocket to support multiple namespaces within a single
# socket.  PartsSocket should eventually be moved into here.

IdDataDelimiter = "!!\n"

App.CommandSocket = App.BaseSocket.extend
  name: 'command'
  additionalNamespaces: ['search']

  serverURIBinding: 'box.box_server_uri'
  serverName: 'rainbow'

  resultDocuments: {}

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
      [tabId, results] = this.parseIdData(data)
      if docs = @get('resultDocuments')
        if doc = docs[tabId]
          doc.set('content', doc.get('content') + results)

    socket.on 'search.commandError', (data) ->
      console.log("Command error: #{data}")

    socket.on 'search.commandComplete', (code) ->
      console.log("Whoops: #{code}")

  parseIdData: (data) ->
    return data.split(IdDataDelimiter)

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
    tabId = (Date.now() + Math.random()).toString()
    this.sendAs 'search', 'search', tabId, term, path, =>
      editorController = App.get('router.ideEditorController')
      termTitle = if term.length > 6 then term.slice(0, 6) + "..." else term
      doc = editorController.createTab
        content: "Searching...\n\n"
        path:
          name: "Search results: '#{termTitle}'" # used for tab title
        contentType: 'search-results'
      documents = @get('resultDocuments')
      documents[tabId] = doc
      @set("resultDocuments", documents)
