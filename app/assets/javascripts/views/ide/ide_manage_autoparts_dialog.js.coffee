AIO.IdeManageAutopartsDialogView = AIO.IdeModalDialogView.extend
  templateName: 'templates/ide/manage_autoparts_dialog'
  elementId: 'ide_manage_autoparts_dialog_view'
  contentBinding: 'controller.manageDialog' # controller = ideAutopartsController

  loading: true
  hidden: true

  parts: null
  visibleParts: null

  filter: null
  loadParts: null
  searchTerm: null
  showInstalled: false

  partsPerPage: 3
  currentPage: 0

  totalPages: (->
    if parts = @get('parts')
      partsCount = parts.get 'length'
      partsPerPage = @get 'partsPerPage'
      Math.ceil (partsCount / partsPerPage)
  ).property 'parts'

  viewDidAppear: ->
    @_super()
    @set 'hidden', false

  viewDidDisappear: ->
    @set 'hidden', true
    @set 'searchTerm', null
    @set 'currentPage', 0 # reset back to first page

  hidePager: (->
    @get('loading') || @get('totalPages') < 2
  ).property 'loading', 'totalPages'

  inFirstPage: (->
    @get('currentPage') == 1
  ).property 'currentPage'

  inLastPage: (->
    @get('currentPage') == @get('totalPages')
  ).property 'currentPage', 'totalPages'

  didClickNext: ->
    @incrementProperty 'currentPage'

  didClickPrevious: ->
    @decrementProperty 'currentPage'

  # Try loading parts, only when dialog becomes visible and
  # if controller itself has finished loading the parts.
  _loadParts: (->
    return if @get 'hidden'
    @get('controller').all (parts) =>
      @set 'parts', parts
      @set 'loading', false
      @set 'currentPage', 1
  ).observes 'controller.parts', 'hidden'

  _searchForParts: (->
    @set 'loading', true
    @set 'currentPage', 0
    @get('controller').search @get('searchTerm'), @get('showInstalled'), (matchingParts) =>
      @set 'parts', matchingParts
      @set 'loading', false
      @set 'currentPage', 1
  ).observes 'searchTerm', 'showInstalled'

  _setVisibleParts: (->
    return unless parts = @get('parts')
    if (currentPage = @get 'currentPage') > 0
      partsPerPage = @get 'partsPerPage'
      partsStart = (currentPage - 1) * partsPerPage
      partsEnd = partsStart + partsPerPage
      @set 'visibleParts', parts.slice(partsStart, partsEnd)
  ).observes 'currentPage'
