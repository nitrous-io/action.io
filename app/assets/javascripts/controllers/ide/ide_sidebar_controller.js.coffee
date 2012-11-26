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
    if !path.get("isDeleted") && !path.get('loading') && @get('sftpSocketReady')
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

  newPath: (path, directory) ->
    this.openPath path if !path.get 'expanded'
    newPath = AIO.Path.create
      absolutePath: "#{path.get('absolutePath')}/__aio_untitled_path__"
      new: true
      editable: true
      directory: directory
    path.addObject newPath

  saveNewPath: (path, name) ->
    homePath = @get 'homePath'
    parentAbsolutePath = path.get 'parentAbsolutePath'
    if parentPath = homePath.findByRelativePath parentAbsolutePath
      sftpSocket = @get 'sftpSocket'
      absolutePath = _.chain([parentAbsolutePath, name]).compact().join('/').value()

      callback = =>
        path.set 'new', false # temp paths with 'new: false' get removed on refresh
        this.refresh parentPath

      if path.get 'directory'
        sftpSocket.makeDirectory absolutePath, callback
      else
        sftpSocket.writeNewFile absolutePath, '', callback

  cancelNewPath: (path) ->
    homePath = @get 'homePath'
    if parentPath = homePath.findByRelativePath path.get('parentAbsolutePath')
      parentPath.removeObject path

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

  delete: (path) ->
    deleteMethod = if path.get("directory") then "deleteDir" else "deleteFile"
    sftpSocket = @get 'sftpSocket'
    homePath = @get 'homePath'
    parentPath = homePath.findByRelativePath path.get('parentAbsolutePath')
    path.set "deleted", true

    sftpSocket[deleteMethod] path.get('absolutePath'), (err) =>
      if err
        path.set "deleted", false
      else
        parentPath?.removeObject path
        @removeObject path

AIO.IdeSidebarController.reopenClass
  REFRESH_DELAY: 200

