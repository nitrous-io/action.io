AIO.IdeSidebarController = Em.ArrayController.extend
  homePath: null # home (~/) path
  rootPath: null # current root path in the sidebar
  content:  null # array of all path objects
  uploadDialog: null

  sftpSocketBinding: Em.Binding.oneWay 'AIO.router.ideController.sftpSocket'
  sftpSocketReadyBinding: Em.Binding.oneWay 'sftpSocket.started'
  sftpSocketNotReady: (->
    !@get 'sftpSocketReady'
  ).property 'sftpSocketReady'

  hiddenFilesVisible: false

  initialize: ->
    @set 'homePath', homePath = AIO.Path.create absolutePath: '', directory: true
    @set 'rootPath', homePath
    @set 'content', [homePath]

  reset: ->
    @set 'homePath', null
    @set 'rootPath', null
    @set 'content', null
    @set 'uploadDialog', null

  sftpSocketDidStartForTheFirstTime: (->
    if @get 'sftpSocket.startedFirstTime'
      Em.run.next =>
        this.openPath @get('rootPath')
  ).observes 'sftpSocket.startedFirstTime'

  openPath: (path) ->
    if !path.get('loading') && @get('sftpSocketReady')
      if path.get 'directory'
        path.set 'expanded', !path.get('expanded')
        if path.get 'expanded'
          this.fetchFileList path
      else
        editorController = AIO.get 'router.ideEditorController'
        if document = editorController.findProperty 'path', path
          editorController.makeTabActive document
        else
          this.fetchFileContent path

  fetchFileList: (path) ->
    sftpSocket = @get 'sftpSocket'
    path.incrementProperty 'loadCount'
    sftpSocket.fetchFileList path.get('absolutePath'), (err, absolutePath, content) ->
      path.decrementProperty 'loadCount'
      unless err
        path.updateContent content

  fetchFileContent: (path) ->
    sftpSocket = @get 'sftpSocket'
    path.incrementProperty 'loadCount'
    sftpSocket.fetchFileContent path.get('absolutePath'), (err, absolutePath, content) ->
      path.decrementProperty 'loadCount'
      unless err
        editorController = AIO.get 'router.ideEditorController'
        editorController.createTab content: content, path: path

  refresh: (path) ->
    if path.get('directory') && path.get('expanded')
      delay = 0

      for subpath in path.get 'arrangedContent'
        if subpath.get('directory') && subpath.get('expanded')
          delay += @constructor.REFRESH_DELAY
          ((controller, subpath, delay) ->
            window.setTimeout ->
              controller.refresh subpath
            , delay
          )(this, subpath, delay)

      unless path.get 'loading'
        this.fetchFileList path

  refreshPath: (pathString) ->
    homePath = @get 'homePath'
    if path = homePath.findByRelativePath pathString
      this.refresh path

  refreshAll: ->
    this.refresh @get('rootPath')

  setHomeAsRoot: ->
    @set 'rootPath', @get('homePath')

  setPathAsRoot: (path) ->
    @set 'rootPath', path

  showUploadDialog: (path) ->
    path ?= @get 'homePath'
    @set 'uploadDialog', AIO.UploadDialog.create path: path

  beginUpload: ->
    if uploadDialog = @get 'uploadDialog'
      uploadDialog.set 'uploading', true
      uploadDialog.forEach (upload) ->
        upload.submit()

  sendUploadToken: (path, token) ->
    sftpSocket = @get 'sftpSocket'
    sftpSocket.sendUploadToken path, token, _.bind(@didSendUploadToken, this)

  didSendUploadToken: (err, absolutePath) ->
    path = AIO.Path.create absolutePath: absolutePath
    this.refreshPath path.get('parentAbsolutePath')
    this.didFinishAnUpload()

  didFinishAnUpload: ->
    uploadDialog = @get 'uploadDialog'
    if uploadDialog && uploadDialog.get 'completed'
      @set 'uploadDialog', null

AIO.IdeSidebarController.reopenClass
  REFRESH_DELAY: 200

