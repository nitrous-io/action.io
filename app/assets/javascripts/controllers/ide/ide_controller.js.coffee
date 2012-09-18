AIO.IdeController = Em.ObjectController.extend AIO.FsSocketDelegate,
  homePath: null
  rootPath: null
  fsSocket: null

  initialize: (->
    if content = @get 'content'
      @set 'homePath', homePath = AIO.Path.create absolutePath: ''
      @set 'fsSocket', fsSocket = AIO.FsSocket.create box: content
      @set 'rootPath', homePath

      router = AIO.get 'router'
      router.get('ideEditorController').initialize()
      router.get('ideConsoleController').initialize()

      fsSocket.connect()
      fsSocket.set 'delegate', this
    else
      this.reset()
  ).observes 'content'

  reset: ->
    if fsSocket = @get 'fsSocket'
      fsSocket.set 'delegate', null
      fsSocket.disconnect()

    router = AIO.get 'router'
    router.get('ideEditorController').reset()
    router.get('ideConsoleController').reset()

    @setProperties
      content: null
      homePath: null
      rootPath: null
      fsSocket: null

  redirectToIndexWhenNotRunning: (->
    if content = @get 'content'
      unless content.get('state') == 'running'
        Ember.run.schedule 'sync', ->
          AIO.get('router').transitionTo 'boxes.index'
  ).observes 'content.state'

  # AIO.FsSocketDelegate
  didReceiveFileList: (err, absolutePath, fileList) ->
    homePath = @get 'homePath'
    if path = homePath.findByRelativePath absolutePath
      path.decrementProperty 'loadCount'
      unless err
        path.updateContent fileList

  didReceiveFileContent: (err, absolutePath, content) ->
    homePath = @get 'homePath'
    if path = homePath.findByRelativePath absolutePath
      path.decrementProperty 'loadCount'
      unless err
        editorController = AIO.get 'router.ideEditorController'
        editorController.createTab content: content, path: path

  didWriteFileContent: (err, absolutePath) ->
    homePath = @get 'homePath'
    if path = homePath.findByRelativePath absolutePath
      path.decrementProperty 'loadCount'

