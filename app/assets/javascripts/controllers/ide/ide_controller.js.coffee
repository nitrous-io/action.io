AIO.IdeController = Em.ObjectController.extend AIO.FsSocketDelegate,
  fsSocket: null

  initialize: (->
    if content = @get 'content'
      @set 'fsSocket', fsSocket = AIO.FsSocket.create box: content

      router = AIO.get 'router'
      router.get('ideMainMenuController').initialize()
      router.get('ideSidebarController').initialize()
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
    router.get('ideMainMenuController').reset()
    router.get('ideConsoleController').reset()
    router.get('ideEditorController').reset()
    router.get('ideSidebarController').reset()

    @set 'fsSocket', null
    @set 'content', null

  redirectToIndexWhenNotRunning: (->
    if content = @get 'content'
      unless content.get('state') == 'running'
        Ember.run.schedule 'sync', ->
          AIO.get('router').transitionTo 'boxes.index'
  ).observes 'content.state'

  # AIO.FsSocketDelegate
  didReceiveFileList: (err, absolutePath, fileList) ->
    homePath = AIO.get 'router.ideSidebarController.homePath'
    if path = homePath.findByRelativePath absolutePath
      path.decrementProperty 'loadCount'
      unless err
        path.updateContent fileList

  didReceiveFileContent: (err, absolutePath, content) ->
    homePath = AIO.get 'router.ideSidebarController.homePath'
    if path = homePath.findByRelativePath absolutePath
      path.decrementProperty 'loadCount'
      unless err
        editorController = AIO.get 'router.ideEditorController'
        editorController.createTab content: content, path: path

  didWriteFileContent: (err, absolutePath) ->
    homePath = AIO.get 'router.ideSidebarController.homePath'
    if path = homePath.findByRelativePath absolutePath
      path.decrementProperty 'loadCount'

  didWriteNewFileContent: (err, absolutePath) ->
    editorController = AIO.get 'router.ideEditorController'
    editorController.didWriteNewFileContent err, absolutePath

