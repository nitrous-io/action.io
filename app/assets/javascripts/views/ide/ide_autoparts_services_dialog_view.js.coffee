AIO.IdeAutopartsServicesDialogView = AIO.IdeModalDialogView.extend
  templateName: 'templates/ide/autoparts_services_dialog'
  elementId: 'ide_autoparts_services_dialog_view'
  contentBinding: 'controller.autopartsServicesDialog' # controller = ideAutopartsController

  loading: false
  parts: null
  searchTerm: null

  viewDidAppear: ->
    @_super()
    this._listParts()

  viewDidDisappear: ->
    @set 'parts', null
    @set 'searchTerm', null

  _listParts: ->
    @set 'loading', true
    @get('controller').hasStatus (parts) =>
      console.log parts
      @set 'parts', parts
      @set 'loading', false

  _searchForParts: ->
    @set 'loading', true
    @get('controller').search @get('searchTerm'), (matchingParts) =>
      @set 'parts', matchingParts.filterProperty('status')
      @set 'loading', false

AIO.IdeManageAutopartsTextField = Em.TextField.extend
  insertNewline: (event) ->
    @get('parentView')._searchForParts()
