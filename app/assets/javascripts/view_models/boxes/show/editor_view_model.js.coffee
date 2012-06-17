class AIO.EditorViewModel extends AIO.TabbedViewModel
  constructor: ->
    super()
    @aceReady = ko.observable(false)
    window.setTimeout =>
      this.setupAce()
      this.newDocument()
    , 0

  newDocument: ->
    doc = new AIO.Document
    this.newTab(new AIO.DocumentViewModel(doc))

  newDocumentWithFileAndContent: (file, content) ->
    doc = new AIO.Document
    doc.setContent(content)
    this.newTab(new AIO.DocumentViewModel(doc, file))

  setupAce: ->
    @ace = ace.edit($('#editor')[0])
    @ace.setShowPrintMargin(false)
    @ace.setTheme('ace/theme/solarized_dark')
    @aceReady(true)

  activateTab: (tab) =>
    super(tab)
    @ace.setSession(tab.model().editSession)

