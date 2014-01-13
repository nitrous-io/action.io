AIO.IdeAutopartsRemoveDialogView = AIO.IdeModalDialogView.extend
  templateName: 'templates/ide/autoparts_remove_dialog'
  elementId: 'ide_autoparts_remove_dialog_view'
  contentBinding: 'controller.autopartsRemoveDialog' # controller = ideAutopartsController

  loading: false
  parts: null
  searchTerm: null

  viewDidAppear: ->
    @_super()
    this._listInstalledParts()

  viewDidDisappear: ->
    @set 'parts', null
    @set 'searchTerm', null

  didClickAutopartsInstall: ->
    this.hide()
    AIO.get('router.ideAutopartsController').showAutopartsInstallDialog()

  _listInstalledParts: ->
    @set 'loading', true
    @get('controller').installed (parts) =>
      @set 'parts', parts
      @set 'loading', false

  _searchForParts: ->
    @set 'loading', true
    @get('controller').search @get('searchTerm'), (matchingParts) =>
      @set 'parts', matchingParts.filterProperty('installed')
      @set 'loading', false

AIO.IdeManageAutopartsTextField = Em.TextField.extend
  insertNewline: (event) ->
    @get('parentView')._searchForParts()
