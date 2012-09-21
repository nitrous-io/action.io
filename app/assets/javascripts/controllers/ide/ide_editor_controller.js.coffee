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
    fsSocket = AIO.get 'router.ideController.fsSocket'
    path = document.get 'path'
    if fsSocket && path
      path.incrementProperty 'loadCount'
      fsSocket.writeFile path.get('absolutePath'), document.get('content')

  saveNewDocument: ->
    saveDialog = @get 'saveDialog'
    unless saveDialog.validate()
      saveDialog.set 'saving', true
      documentContent = saveDialog.get 'document.content'
      path = saveDialog.get 'path'
      if fsSocket = AIO.get 'router.ideController.fsSocket'
        fsSocket.writeNewFile path, documentContent

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
      if saveDialogView = Em.View.views.ide_save_dialog_view
        saveDialogView.hide()
    saveDialog.set 'saving', false

