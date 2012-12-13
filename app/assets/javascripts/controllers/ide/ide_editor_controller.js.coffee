# IdeEditorController
# ===================
# Responsisble for managing list of opened `AIO.Document`
#
# Attributes:
# content - list of opened `AIO.Document`
AIO.IdeEditorController = Em.ResourceController.extend AIO.IdeTabControllerMixin,
  resourceType: AIO.Document
  jsonRoot: 'documents'
  modelClass: AIO.Document
  content: null
  saveDialog: null
  confirmCloseDialog: null

  sftpSocketBinding: Em.Binding.oneWay 'AIO.router.ideController.sftpSocket'
  sftpSocketReadyBinding: Em.Binding.oneWay 'sftpSocket.started'

  # hack to workaround ember-rest inability to handle dynamic resourceUrl
  _resourceUrl: () ->
    if contentId = AIO.get 'router.ideController.content.id'
      "/boxes/#{contentId}/documents"

  initialize: ->
    @set 'content', []
    @findAll().done =>
      if tab = @get('content.0')
        @makeTabActive tab

  reset: ->
    @set 'content', null
    @set 'saveDialog', null
    @set 'confirmCloseDialog', null

  # open a new document as an editor tab. The new document will be untitled and
  # will not have a pathname
  createTab: (attrs={}) ->
    AIO.util.mixpanel 'ide:new_document_tab'
    @_super(attrs)

  removeTab: (tab, forceRemove = false) ->
    tab = @get 'activeTab' unless tab
    if tab.get('clean') || forceRemove
      @_super(tab)
      tab.destroy()
    else
      @set 'confirmCloseDialog', AIO.ConfirmCloseDialog.create document: tab

  # open a document as an editor tab. This will create a new document instance,
  # add it to `content` and load the actual content from the box if the document
  # is not being opened. Otherwise, it activates the current document
  #
  # pathname - absolute path of the document
  openDocument: (pathname) ->
    if document = @get('content').findProperty('pathname', pathname)
      @makeTabActive document
    else
      AIO.util.mixpanel 'ide:new_document_tab'
      document = AIO.Document.create pathname: pathname
      document.loadContent (document) =>
        @addTab document
        document.sync()

  saveDocument: (document) ->
    if document.get('pathname')
      AIO.util.mixpanel 'ide:save_existing_document'
      document.saveContent()
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
      saveDialog.set 'document.pathname', absolutePath
      saveDialog.set 'document.lastSavedContent', saveDialog.get 'document.content'
      sidebarController = AIO.get 'router.ideSidebarController'
      sidebarController.refreshPath path.get('parentAbsolutePath')
      @set 'saveDialog', null
    saveDialog.set 'saving', false

