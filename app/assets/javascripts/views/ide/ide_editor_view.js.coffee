AIO.IdeEditorView = AIO.IdeTabView.extend AIO.FileContentDelegate,
  templateName: 'templates/ide/editor'
  elementId: 'ide_editor_view'

  modelClass: AIO.Document
  tabsBinding: 'AIO.router.ideController.documents'

  init: ->
    @_super()
    this.becomeFileContentDelegate()

  willDestroy: ->
    @_super()
    this.resignFileContentDelegate()

  didReceiveFileContent: (err, pathString, content) ->
    homePath = @get 'controller.homePath'
    if path = homePath.findByRelativePath pathString
      path.decrementProperty 'loadCount'
      unless err
        tab = @get('modelClass').create content: content, path: path
        this.addTab tab

