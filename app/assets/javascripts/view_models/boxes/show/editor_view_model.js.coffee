class AIO.EditorViewModel extends AIO.TabbedViewModel
  constructor: ->
    super()
    @aceReady = ko.observable(false)
    window.setTimeout =>
      this.newDocument()
    , 0

    if AIO.events
      AIO.events.on 'openTabForFileWithCid', this.onOpenTabForFileWithCid

  newDocument: ->
    doc = new AIO.Document
    this.newTab(new AIO.DocumentViewModel(doc))

  newDocumentWithFileVMAndContent: (fileVM, content) ->
    doc = new AIO.Document(content: content)
    this.newTab(new AIO.DocumentViewModel(doc, fileVM))

  tabForFileWithCid: (cid) =>
    if tabs = @tabs()
      _.find tabs, (tab) -> tab.fileVM?.model()?.cid == cid

  onOpenTabForFileWithCid: (cid) =>
    if docVM = this.tabForFileWithCid(cid)
      this.activateTab(docVM)

  __destroy: ->
    if AIO.events
      AIO.events.off 'openTabForFileWithCid', this.onOpenTabForFileWithCid
    super()

