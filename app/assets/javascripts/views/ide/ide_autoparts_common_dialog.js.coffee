AIO.IdeAutopartsCommonDialogView = AIO.IdeModalDialogView.extend
  templateName: 'templates/ide/autoparts_common_dialog'

  servicesView: false
  loading: true

  parts: null
  visibleParts: null

  dialogTitle: null
  filterPlaceholder: null
  filter: null
  loadParts: null
  searchTerm: null

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
    this._loadParts()

  viewDidDisappear: ->
    @set 'parts', null
    @set 'searchTerm', null

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

  _loadParts: ->
    @set 'loading', true
    @set 'currentPage', 0
    this.loadParts (parts) =>
      @set 'parts', parts
      @set 'loading', false

  _searchForParts: (->
    @set 'loading', true
    @set 'currentPage', 0
    @get('controller').search @get('searchTerm'), (matchingParts) =>
      @set 'parts', this.filter(matchingParts)
      @set 'loading', false
  ).observes 'searchTerm'

  _resetCurrentPage: (->
    @set 'currentPage', 1
  ).observes 'parts'

  _setVisibleParts: (->
    if (currentPage = @get 'currentPage') > 0
      partsPerPage = @get 'partsPerPage'
      partsStart = (currentPage - 1) * partsPerPage
      partsEnd = partsStart + partsPerPage
      @set 'visibleParts', @get('parts').slice(partsStart, partsEnd)
  ).observes 'currentPage'
