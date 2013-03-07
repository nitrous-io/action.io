AIO.IdeSidebarController = Em.ArrayController.extend
  needs: ['ide', 'ideEditor', 'ideLayout']
  homePath: null # home (~/) path
  rootPath: null # current root path in the sidebar
  content:  null # array of all path objects
  uploadDialog: null

  sftpSocketBinding: Em.Binding.oneWay 'controllers.ide.sftpSocket'
  sftpSocketReadyBinding: Em.Binding.oneWay 'sftpSocket.started'

  sftpSocketNotReady: (->
    !@get 'sftpSocketReady'
  ).property 'sftpSocketReady'

  hiddenFilesVisible: false

  initialize: ->
    @set 'homePath', homePath = AIO.Path.create this, absolutePath: '', directory: true
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
        editorController = @get 'controllers.ideEditor'
        if document = editorController.findProperty 'path', path
          editorController.makeTabActive document
        else
          this.fetchFileContent path

  fetchFileList: (path) ->
    sftpSocket = @get 'sftpSocket'
    path.incrementProperty 'loadCount'
    sftpSocket.fetchFileList path.get('absolutePath'), (err, absolutePath, content) =>
      path.decrementProperty 'loadCount'
      unless err
        path.updateContent this, content

  fetchFileContent: (path) ->
    sftpSocket = @get 'sftpSocket'
    path.incrementProperty 'loadCount'
    sftpSocket.fetchFileContent path.get('absolutePath'), (err, absolutePath, contentType, content) =>
      path.decrementProperty 'loadCount'
      if err
        window.alert "Cannot open the selected file."
        return
      editorController = @get 'controllers.ideEditor'
      editorController.createTab content: content, path: path, contentType: contentType

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

  rootPathDidChange: (->
    rootPath = @get('rootPath')
    return unless rootPath
    unless rootPath.get('isRootPath')
      rootPath.set 'isRootPath', true
      this.filter((item) -> item != rootPath).forEach (item) ->
        item.set 'isRootPath', false
  ).observes 'rootPath'

  newPath: (path, directory) ->
    this.openPath path if !path.get 'expanded'
    newPath = AIO.Path.create this,
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
      parentPath.get('content').removeObject(path)

  renamePath: (path) ->
    path.set 'editable', true

  applyRenamedPath: (path, newPathName) ->
    if newPathName == path.get 'name'
      return @resetRenamedPath path

    homePath = @get 'homePath'
    parentAbsolutePath = path.get 'parentAbsolutePath'

    makeAbsolutePath = (pathName) ->
      _.chain([parentAbsolutePath, pathName]).compact().join('/').value()

    if parentPath = homePath.findByRelativePath parentAbsolutePath
      sftpSocket = @get 'sftpSocket'
      currentPathName = path.get 'name'
      currentAbsolutePath = makeAbsolutePath currentPathName
      newAbsolutePath = makeAbsolutePath newPathName
      path.incrementProperty 'loadCount'

      callback = (err) =>
        path.decrementProperty 'loadCount'

        if err
          path.set 'editable', false
          if err == 'aio:name_taken'
            window.alert "The name “#{newPathName}” is already taken. Please choose a different name."
          else
            window.alert 'Rename failed.'

        this.refresh parentPath

      sftpSocket.rename currentAbsolutePath, newAbsolutePath, callback

  resetRenamedPath: (path) ->
    path.set 'editable', false

  showUploadDialog: (path) ->
    path ?= @get 'homePath'
    AIO.util.mixpanel 'Opened File Upload Dialog'
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
    path = AIO.Path.create this, absolutePath: absolutePath
    this.refreshPath path.get('parentAbsolutePath')
    this.didFinishAnUpload()

  didFinishAnUpload: ->
    uploadDialog = @get 'uploadDialog'
    if uploadDialog && uploadDialog.get 'completed'
      AIO.util.mixpanel 'Uploaded File'
      @set 'uploadDialog', null

  delete: (path) ->
    return if path == @get 'rootPath'
    deleteMethod = if path.get('directory') then 'deleteDir' else 'deleteFile'
    sftpSocket = @get 'sftpSocket'
    homePath = @get 'homePath'
    parentPath = homePath.findByRelativePath path.get('parentAbsolutePath')
    path.set 'beingDeleted', true
    path.incrementProperty 'loadCount'

    sftpSocket[deleteMethod] path.get('absolutePath'), (err) =>
      if err
        path.decrementProperty 'loadCount'
        path.set 'beingDeleted', false
      else
        parentPath?.removeObject path
        this.removeObject path # TODO: not strictly necessary but, remove all children paths recursively from 'content' too?

AIO.IdeSidebarController.reopenClass
  REFRESH_DELAY: 200

