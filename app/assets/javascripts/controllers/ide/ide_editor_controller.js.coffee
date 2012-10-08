AIO.IdeEditorController = Em.ArrayController.extend AIO.IdeTabControllerMixin,
  modelClass: AIO.Document
  content: null
  saveDialog: null

  initialize: ->
    @set 'content', []

  reset: ->
    @set 'content', null
    @set 'saveDialog', null

  saveDocument: (document) ->
    if path = document.get 'path'
      if sftpSocket = AIO.get 'router.ideController.sftpSocket'
        path.incrementProperty 'loadCount'
        sftpSocket.writeFile path.get('absolutePath'), document.get('content')
    else
      @set 'saveDialog', AIO.SaveDialog.create document: document, visible: true

  saveNewDocument: ->
    saveDialog = @get 'saveDialog'
    unless saveDialog.validate()
      saveDialog.set 'saving', true
      documentContent = saveDialog.get 'document.content'
      path = saveDialog.get 'path'
      if sftpSocket = AIO.get 'router.ideController.sftpSocket'
        sftpSocket.writeNewFile path, documentContent

  didWriteNewFileContent: (err, absolutePath) ->
    saveDialog = @get 'saveDialog'
    if err
      errors = {}
      if err.indexOf('aio:file_exists') != -1
        errors.path = ['A file already exists in the path.']
      else if err.indexOf('aio:folder_exists') != -1
        errors.path = ['A folder already exists in the path.']
      else
        errors.base = [err]
      saveDialog.set 'errors', errors
    else
      path = AIO.Path.createAndAddToAllPaths absolutePath: absolutePath
      saveDialog.set 'document.path', path
      parentDirectoryPath = absolutePath.split('/').slice(0, -1).join('/') + '/'
      homePath = AIO.get 'router.ideSidebarController.homePath'
      if parentPath = homePath.findByRelativePath parentDirectoryPath
        parentPath.addObject path
      saveDialog.set 'visible', false
    saveDialog.set 'saving', false

