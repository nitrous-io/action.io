AIO.IdeManageAutopartsDialogView = AIO.IdeModalDialogView.extend
  templateName: 'templates/ide/manage_autoparts_dialog'
  elementId: 'ide_manage_autoparts_dialog_view'
  contentBinding: 'controller.manageAutopartsDialog' # controller = ideAutopartsController

  loading: false
  partsType: null
  parts: null
  searchTerm: null

  partsTypeTitle: (->
    if partsType = @get('partsType')
      partsType.capitalize() + " Packages"
  ).property 'partsType'

  viewDidAppear: ->
    @_super()
    this._showInstalledOrRecommendedPackages()

  viewDidDisappear: ->
    @set 'parts', null
    @set 'partsType', null
    @set 'searchTerm', null

  _showInstalledOrRecommendedPackages: ->
    @set 'loading', true
    @get('controller').installed (installedParts) =>
      if installedParts.get('length')
        @set 'partsType', 'installed'
        @set 'parts', installedParts
      else
        @get('controller').recommended (recommendedParts) =>
          @set 'partsType', 'recommended'
          @set 'parts', recommendedParts
      @set 'loading', false

  _searchForParts: ->
    @set 'loading', true
    @get('controller').search @get('searchTerm'), (matchingParts) =>
      @set 'partsType', 'matching'
      @set 'parts', matchingParts
      @set 'loading', false

AIO.IdeManageAutopartsTextField = Em.TextField.extend
  insertNewline: (event) ->
    @get('parentView')._searchForParts()
