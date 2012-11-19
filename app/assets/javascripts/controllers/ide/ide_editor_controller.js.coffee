AIO.IdeEditorController = Em.ArrayController.extend AIO.IdeTabControllerMixin,
  modelClass: AIO.Document
  content: null
  saveDialog: null

  sftpSocketBinding: Em.Binding.oneWay 'AIO.router.ideController.sftpSocket'
  sftpSocketReadyBinding: Em.Binding.oneWay 'sftpSocket.started'

  initialize: ->
    @set 'content', []

  reset: ->
    @set 'content', null
    @set 'saveDialog', null

  createTab: (attrs={}) ->
    AIO.util.mixpanel 'ide:new_document_tab'
    @_super(attrs)

  saveDocument: (document) ->
    return unless @get 'sftpSocketReady'
    if path = document.get 'path'
      AIO.util.mixpanel 'ide:save_existing_document'
      if sftpSocket = @get 'sftpSocket'
        path.incrementProperty 'loadCount'
        sftpSocket.writeFile path.get('absolutePath'), document.get('content'), (err, absolutePath) ->
          path.decrementProperty 'loadCount'
    else
      @set 'saveDialog', AIO.SaveDialog.create document: document

  saveNewDocument: ->
    return unless @get 'sftpSocketReady'
    saveDialog = @get 'saveDialog'
    unless saveDialog.validate()
      AIO.util.mixpanel 'ide:save_new_document'
      saveDialog.set 'saving', true
      documentContent = saveDialog.get 'document.content'
      path = saveDialog.get 'path'
      if sftpSocket = @get 'sftpSocket'
        sftpSocket.writeNewFile path, documentContent, _.bind(@didWriteNewFileContent, this)

  didWriteNewFileContent: (err, absolutePath) ->
    saveDialog = @get 'saveDialog'
    if err
      errors = {}
      if err.indexOf('aio:file_exists') != -1
        errors.path = ['A file already exists in the path.']
      else
        errors.base = [err]
      saveDialog.set 'errors', errors
    else
      path = AIO.Path.create absolutePath: absolutePath
      saveDialog.set 'document.path', path
      sidebarController = AIO.get 'router.ideSidebarController'
      sidebarController.refreshPath path.get('parentAbsolutePath')
      @set 'saveDialog', null
    saveDialog.set 'saving', false

