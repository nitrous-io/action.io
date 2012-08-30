class AIO.EditorViewModel extends AIO.TabbedViewModel
  constructor: ->
    super()
    @aceReady = ko.observable(false)
    window.setTimeout =>
      this.newDocument()
    , 0

    if AIO.events
      AIO.events.on 'openTabForFileWithPath', this.onOpenTabForFileWithPath

  newDocument: ->
    doc = new AIO.Document
    this.newTab(new AIO.DocumentViewModel(doc))

  newDocumentWithFileVMAndContent: (fileVM, content) ->
    doc = new AIO.Document(content: content)
    this.newTab(new AIO.DocumentViewModel(doc, fileVM))

  tabForFileWithPath: (path) =>
    if tabs = @tabs()
      _.find tabs, (tab) -> tab.fileVM?.path() == path

  onOpenTabForFileWithPath: (path) =>
    if docVM = this.tabForFileWithPath(path)
      this.activateTab(docVM)

  __destroy: ->
    if AIO.events
      AIO.events.off 'openTabForFileWithPath', this.onOpenTabForFileWithPath
    super()

