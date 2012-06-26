class AIO.EditorViewModel extends AIO.TabbedViewModel
  constructor: ->
    super()
    @aceReady = ko.observable(false)
    window.setTimeout =>
      this.newDocument()
    , 0

    @fileCidTabMap = ko.computed =>
      map = {}
      for tab in @tabs()
        if model = tab.fileVM?.model()
          map[model.cid] = tab
      map

    AIO.events.on 'openTabForFileWithCid', (cid) =>
      if docVM = this.fileCidTabMap()[cid]
        this.activateTab(docVM)

  newDocument: ->
    doc = new AIO.Document
    this.newTab(new AIO.DocumentViewModel(doc))

  newDocumentWithFileVMAndContent: (fileVM, content) ->
    doc = new AIO.Document(content: content)
    this.newTab(new AIO.DocumentViewModel(doc, fileVM))

