AIO.IdeController = Em.ObjectController.extend
  documents: null
  consoleSessions: null
  homePath: null
  rootPath: null
  fsSocket: null

  initialize: (->
    if content = @get 'content'
      @setProperties
        documents: []
        consoleSessions: []
        homePath: AIO.Path.create(absolutePath: '')
        fsSocket: fsSocket = AIO.FSSocket.create(box: content)
      @set 'rootPath', @get('homePath')
      fsSocket.connect()
    else
      this.reset()
  ).observes 'content'

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

