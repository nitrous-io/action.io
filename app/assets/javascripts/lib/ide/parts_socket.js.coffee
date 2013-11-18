AIO.PartsSocket = AIO.BaseSocket.extend
  namespace: 'parts'

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
