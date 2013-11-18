AIO.IdeManageAutopartsDialogView = AIO.IdeModalDialogView.extend
  templateName: 'templates/ide/manage_autoparts_dialog'
  elementId: 'ide_manage_autoparts_dialog_view'
  contentBinding: 'controller.manageAutopartsDialog' # controller = ideAutopartsController

  loading: false
  partsType: null
  parts: null

  installedPartsCount: (->
    if installedParts = @get('controller.installedParts')
      "#{installedParts.get('length')} installed"
  ).property 'controller.installedParts'

  allPartsCount: (->
    if allParts = @get('controller.allParts')
      "#{allParts.get('length')} available"
  ).property 'controller.allParts'


  partsTypeTitle: (->
    if partsType = @get('partsType')
      partsType.capitalize() + " Packages"
  ).property 'partsType'

  viewDidAppear: ->
    @_super()
    @set 'loading', true
    this._showInstalledOrRecommendedPackages()

  _showInstalledOrRecommendedPackages: ->
    installedParts = @get('controller.installedParts')
    # list not loaded yet,
    # try again after a delay
    unless installedParts
      return window.setTimeout(=>
        this._showInstalledOrRecommendedPackages()
      , 100)
    if installedParts.get('length')
      @set 'partsType', 'installed'
      @set 'parts', installedParts
    else
      @set 'partsType', 'recommended'
      @set 'parts', @get('content.recommendedParts')
    @set 'loading', false

  _searchForParts: (value) ->
    @set 'loading', true
    @get('controller').search value, (matchingParts) =>
      @set 'partsType', 'matching'
      @set 'parts', matchingParts
      @set 'loading', false

AIO.IdeManageAutopartsTextField = Em.TextField.extend
  insertNewline: (event) ->
    @get('parentView')._searchForParts @get('value')
