AIO.IdeAutopartsInstallDialogView = AIO.IdeModalDialogView.extend
  templateName: 'templates/ide/autoparts_install_dialog'
  elementId: 'ide_autoparts_install_dialog_view'
  contentBinding: 'controller.autopartsInstallDialog' # controller = ideAutopartsController

  loading: false
  parts: null
  searchTerm: null

  viewDidAppear: ->
    @_super()
    this._listAllParts()

  viewDidDisappear: ->
    @set 'parts', null
    @set 'searchTerm', null

  _listAllParts: ->
    @set 'loading', true
    @get('controller').available (parts) =>
      @set 'parts', parts
      @set 'loading', false

  _searchForParts: ->
    @set 'loading', true
    @get('controller').search @get('searchTerm'), (matchingParts) =>
      @set 'parts', matchingParts.rejectProperty('installed')
      @set 'loading', false

AIO.IdeManageAutopartsTextField = Em.TextField.extend
  insertNewline: (event) ->
    @get('parentView')._searchForParts()
