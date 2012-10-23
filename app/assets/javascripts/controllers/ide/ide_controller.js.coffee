AIO.IdeController = Em.ObjectController.extend AIO.SftpSocketDelegate,
  sftpSocket: null

  initialize: (->
    if content = @get 'content'
      @set 'sftpSocket', sftpSocket = AIO.SftpSocket.create box: content

      router = AIO.get 'router'
      router.get('ideLayoutController').initialize()
      router.get('ideMainMenuController').initialize()
      router.get('ideSidebarController').initialize()
      router.get('ideEditorController').initialize()
      router.get('ideConsoleController').initialize()

      sftpSocket.connect()
      sftpSocket.set 'delegate', this
    else
      this.reset()
  ).observes 'content'

  reset: ->
    if sftpSocket = @get 'sftpSocket'
      sftpSocket.set 'delegate', null
      sftpSocket.disconnect()

    router = AIO.get 'router'
    router.get('ideLayoutController').reset()
    router.get('ideMainMenuController').reset()
    router.get('ideConsoleController').reset()
    router.get('ideEditorController').reset()
    router.get('ideSidebarController').reset()

    @set 'sftpSocket', null
    @set 'content', null

  redirectToIndexWhenNotRunning: (->
    if content = @get 'content'
      unless content.get('state') == 'running'
        Em.run.schedule 'sync', ->
          AIO.get('router').transitionTo 'boxes.index'
  ).observes 'content.state'

  # AIO.SftpSocketDelegate
  sftpSocketDidStartForTheFirstTime: (sftpSocket) ->
    sidebarController = AIO.get 'router.ideSidebarController'
    sidebarController.openPath sidebarController.get('rootPath')

  sftpSocketDidReceiveFileList: (sftpSocket, err, absolutePath, fileList) ->
    homePath = AIO.get 'router.ideSidebarController.homePath'
    if path = homePath.findByRelativePath absolutePath
      path.decrementProperty 'loadCount'
      unless err
        path.updateContent fileList

  sftpSocketDidReceiveFileContent: (sftpSocket, err, absolutePath, content) ->
    homePath = AIO.get 'router.ideSidebarController.homePath'
    if path = homePath.findByRelativePath absolutePath
      path.decrementProperty 'loadCount'
      unless err
        editorController = AIO.get 'router.ideEditorController'
        editorController.createTab content: content, path: path

  sftpSocketDidWriteFileContent: (sftpSocket, err, absolutePath) ->
    homePath = AIO.get 'router.ideSidebarController.homePath'
    if path = homePath.findByRelativePath absolutePath
      path.decrementProperty 'loadCount'

  sftpSocketDidWriteNewFileContent: (sftpSocket, err, absolutePath) ->
    editorController = AIO.get 'router.ideEditorController'
    editorController.didWriteNewFileContent err, absolutePath

  sftpSocketDidSendUploadToken: (sftpSocket, err, absolutePath) ->
    sidebarController = AIO.get 'router.ideSidebarController'
    sidebarController.didSendUploadToken err, absolutePath

