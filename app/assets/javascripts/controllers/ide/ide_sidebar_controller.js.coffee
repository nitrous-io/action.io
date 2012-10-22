AIO.IdeSidebarController = Em.ArrayController.extend
  homePath: null # home (~/) path
  rootPath: null # current root path in the sidebar
  content:  null # array of all path objects
  uploadDialog: null

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

  openPath: (path) ->
    sftpSocketStarted = AIO.get 'router.ideController.sftpSocket.started'
    if !path.get('loading') && sftpSocketStarted
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
    sftpSocket = AIO.get 'router.ideController.sftpSocket'
    path.incrementProperty 'loadCount'
    sftpSocket.fetchFileList path.get 'absolutePath'

  fetchFileContent: (path) ->
    sftpSocket = AIO.get 'router.ideController.sftpSocket'
    path.incrementProperty 'loadCount'
    sftpSocket.fetchFileContent path.get 'absolutePath'

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
    sftpSocket = AIO.get 'router.ideController.sftpSocket'
    sftpSocket.sendUploadToken path, token

  didSendUploadToken: (err, absolutePath) ->
    path = AIO.Path.create absolutePath: absolutePath
    sidebarController = AIO.get 'router.ideSidebarController'
    sidebarController.refreshPath path.get('parentAbsolutePath')

    uploadDialog = @get 'uploadDialog'
    if uploadDialog && uploadDialog.get 'completed'
      @set 'uploadDialog', null

AIO.IdeSidebarController.reopenClass
  REFRESH_DELAY: 200

