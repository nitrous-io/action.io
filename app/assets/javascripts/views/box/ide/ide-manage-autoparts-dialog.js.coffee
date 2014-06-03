App.IdeManageAutopartsDialogView = App.IdeModalDialogView.extend
  templateName: 'templates/box/ide/manage-autoparts-dialog'
  elementId: 'ide_manage_autoparts_dialog_view'
  contentBinding: 'controller.manageDialog' # controller = ideAutopartsController

  loading: true
  hidden: true
  categoriesView: false
  processingView: false

  parts: null
  visibleParts: null

  filter: null
  loadParts: null
  searchTerm: null
  showInstalled: false

  partsPerPage: 4
  currentPage: 0

  totalPages: (->
    if parts = @get('parts')
      partsCount = parts.get 'length'
      partsPerPage = @get 'partsPerPage'
      Math.ceil (partsCount / partsPerPage)
  ).property 'parts'

  viewDidAppear: ->
    @_super()
    @set 'categoriesView', true
    @set 'hidden', false

  viewDidDisappear: ->
    @set 'hidden', true
    @set 'categoriesView', false
    @set 'searchTerm', null
    @set 'currentPage', 0 # reset back to first page

  hidePager: (->
    @get('loading') || @get('categoriesView') || @get('controller.processing') || @get('totalPages') < 2
  ).property 'loading', 'categoriesView', 'totalPages', 'controller.processing'

  inFirstPage: (->
    @get('currentPage') == 1
  ).property 'currentPage'

  inLastPage: (->
    @get('currentPage') == @get('totalPages')
  ).property 'currentPage', 'totalPages'

  processingView: (->
    @get('controller.processing') || null
  ).property 'controller.processing'

  showDoneButton: (->
    @get('processingView') && @get('controller.partsSocket.outputStream.completed')
  ).property 'controller.partsSocket.outputStream.completed', 'processingView'

  didClickNext: ->
    @incrementProperty 'currentPage'

  didClickPrevious: ->
    @decrementProperty 'currentPage'

  didClickDone: ->
    if controller = @get 'controller'
      controller.set 'processing', false
      controller.set 'processingPart', null

  showPartsByCategory: (category) ->
    this._filterParts (callback) =>
      @get('controller').filterByCategory category, callback

  searchParts: ->
    this._filterParts (callback) =>
      @get('controller').search @get('searchTerm'), @get('showInstalled'), callback

  _didSearchTermChange: (->
    return if !@get('controller.parts') # return if parts are not loaded

    if @get('searchTerm')?.length
      this.searchParts()
    else
      @set 'categoriesView', true
  ).observes 'searchTerm'

  _didShowInstalledSelect: (->
    return if !@get('controller.parts') # return if parts are not loaded

    if @get('showInstalled')
      this.searchParts()
    else
      @set 'categoriesView', true
  ).observes 'showInstalled'

  _didPartsLoad:(->
    if @get('controller.parts')
      @set 'loading', false
  ).observes 'controller.parts'

  _filterParts: (filterFunction) ->
    @set 'categoriesView', false
    @set 'loading', true
    @set 'currentPage', 0

    filterFunction (filteredParts) =>
      @set 'parts', filteredParts
      @set 'loading', false
      @set 'currentPage', 1

  # when returning back from process view,
  # re-search the updated parts list
  # and correctly filter installed/uninstalled parts
  _didReturnFromProcessingView: (->
    return if @get 'processingView'
    @set 'categoriesView', true
  ).observes 'processingView'

  _setVisibleParts: (->
    return unless parts = @get('parts')
    if (currentPage = @get 'currentPage') > 0
      partsPerPage = @get 'partsPerPage'
      partsStart = (currentPage - 1) * partsPerPage
      partsEnd = partsStart + partsPerPage
      visibleParts = parts.slice(partsStart, partsEnd)

      @set 'visibleParts', visibleParts

      # If a page lists only one part,
      # and if it's uninstalled,
      # list should be set to the previous page.
      unless visibleParts.length
        @decrementProperty 'currentPage'
  ).observes 'currentPage', 'parts'
