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

  currentlySelectedPath: null

  # attributes used for drag&drop
  currentlyDraggedPath: null
  currentDroppable: null

  initialize: ->
    @set 'homePath', homePath = AIO.Path.create absolutePath: '', directory: true
    @set 'rootPath', homePath
    @set 'content', [homePath]

  reset: ->
    @set 'homePath', null
    @set 'rootPath', null
    @set 'content', null
    @set 'uploadDialog', null
    @set 'currentlyDraggedPath', null
    @set 'currentDroppable', null

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
    sftpSocket.fetchFileContent path.get('absolutePath'), (err, absolutePath, contentType, content) ->
      path.decrementProperty 'loadCount'
      if err
        window.alert "Cannot open the selected file."
        return

      editorController = AIO.get 'router.ideEditorController'
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
      parentPath.get('content').removeObject path

  renamePath: (path) ->
    path.set 'editable', true

  # apply rename operations to path
  # - path: the path object that we want to rename
  # - newPath: the path object / new name of the path.
  # - isDrag: if true, newPath will be the new path object that we drag the
  # path into a.k.a new parent path
  applyRenamedPath: (path, newPath, isDrag) ->
    if typeof newPath == "string"
      return this.resetRenamedPath path if newPath == path.get 'name'
    if isDrag && !(newPath instanceof AIO.Path)
      return console.warning("expected a AIO.Path object")
    if !isDrag && !(typeof newPath == "string")
      return console.warning("expected a path string")

    homePath = @get('homePath')
    parentAbsolutePath = path.get 'parentAbsolutePath'
    # current directory that hold the path
    parentPath = homePath.findByRelativePath parentAbsolutePath
    return unless parentPath

    sftpSocket = @get 'sftpSocket'
    currentPathName = path.get 'name'

    if isDrag
      # if this is a drag operation, newPath is going to be the path that we drag
      # the file into, while the name of the file will be kept
      newParentPath = newPath.get('absolutePath')
      newPathName = currentPathName
    else
      # otherwise, this is the rename operation, which the parentPath will be
      # kept and the file will have a new name
      newParentPath = parentAbsolutePath
      newPathName = newPath

    currentAbsolutePath = this._makeAbsolutePath parentAbsolutePath, currentPathName
    newAbsolutePath = this._makeAbsolutePath newParentPath, newPathName

    path.incrementProperty 'loadCount'
    sftpSocket.rename currentAbsolutePath, newAbsolutePath, (err) =>
      path.decrementProperty 'loadCount'
      if err
        path.set 'editable', false
        if err == 'aio:name_taken'
          window.alert "The name “#{newPathName}” is already taken. Please choose a different name."
        else
          window.alert 'Rename failed.'
      this.refresh parentPath
      this.refresh newPath if isDrag

  resetRenamedPath: (path) ->
    path.set 'editable', false

  showUploadDialog: (path) ->
    path ?= @get 'rootPath'
    AIO.util.mixpanel 'Opened File Upload Dialog'
    @set 'uploadDialog', AIO.UploadDialog.create path: path

  beginUpload: ->
    uploadDialog = @get 'uploadDialog'
    if uploadDialog && uploadDialog.get('length')
      uploadDialog.set 'uploading', true
      uploadDialog.forEach (upload) ->
        upload.submit()
    else
      @set 'uploadDialog', null

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
        if parentPath
          parentPath.get('content').removeObject path
        # TODO: not strictly necessary but, remove all children paths recursively from 'content' too?
        this.get('content').removeObject path

  moveDraggedPathTo: (path) ->
    draggedPath = @get 'currentlyDraggedPath'
    absoluteDroppablePath = path.get 'absolutePath'
    #expand the droppable path
    path.set 'expanded', true
    this.applyRenamedPath draggedPath, path, true
    @set 'currentlyDraggedPath', null
    @set 'currentDroppable', null

  _makeAbsolutePath: (parentAbsolutePath, fileName) ->
    _.chain([parentAbsolutePath, fileName]).compact().join('/').value()

AIO.IdeSidebarController.reopenClass
  REFRESH_DELAY: 200

