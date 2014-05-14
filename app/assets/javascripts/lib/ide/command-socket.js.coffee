# Overrides sections of BaseSocket to support multiple namespaces within a single
# socket.  PartsSocket should eventually be moved into here.

IdDataDelimiter = "!!\n"

App.CommandSocket = App.BaseSocket.extend
  name: 'command'
  additionalNamespaces: ['search']

  serverURIBinding: 'box.box_server_uri'
  serverName: 'rainbow'

  resultDocuments: null

  init: ->
    @_super()
    @set('resultDocuments', Em.Object.create())

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
      if doc = @get("resultDocuments.#{tabId}")
        Em.run.next ->
          doc.addSearchResults(results)

    socket.on 'search.commandError', (data) ->
      console.log("Command error: #{data}")

    socket.on 'search.commandComplete', (data) =>
      [tabId, code] = this.parseIdData(data)
      if doc = @get("resultDocuments.#{tabId}")
        Em.run.next ->
          doc.addCurrentResult()

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

  search: (term, path, options, callback) ->
    tabId = (Date.now() + parseInt(Math.random() * 1000)).toString()
    this.sendAs 'search', 'search', tabId, term, path, options, =>
      callback(tabId)

