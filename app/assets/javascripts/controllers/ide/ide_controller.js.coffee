AIO.IdeController = Em.ObjectController.extend
  documents: null
  consoleSessions: null
  homePath: null
  rootPath: null
  fsSocket: null

  initialize: ->
    @set 'documents', []
    @set 'consoleSessions', []
    @set 'homePath', AIO.Path.create absolutePath: ''
    @set 'rootPath', @get('homePath')

  reset: ->
    if fsSocket = @get 'fsSocket'
      fsSocket.disconnect()

    @setProperties
      content: null
      documents: null
      consoleSessions: null
      homePath: null
      rootPath: null
      fsSocket: null

  setContentByBoxId: (id) ->
    this.initialize()
    box = AIO.get('router.boxesController').findById(id) || AIO.Box.create id: id
    box.findResource()
    @set 'content', box
    @set 'fsSocket', fsSocket = AIO.FSSocket.create box: box

