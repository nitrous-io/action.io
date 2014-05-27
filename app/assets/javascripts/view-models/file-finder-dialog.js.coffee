App.FileFinderDialog = klass = Em.Object.extend
  pattern: null
  basePath: null
  results: null

  selectedIndex: null
  currentSearch: null

  error: null

  init: ->
    @_super()
    @set 'results', Em.Object.create()
    @set 'selectedIndex', 0

  # returns falsey if results need to be populated via websockets filefind
  find: (pattern, path) ->
    return true if this.hasResults(pattern, path)?
    this.filterResults(pattern, path)

  # if remaining results are less than maxResults, we filter client-side
  filterResults: (pattern, path) ->
    results = @get('currentResults')
    return if !results
    canFilter = pattern.length > 1 && this.hasResults(pattern.slice(0, -1), path) &&
      results.length < klass.maxResults
    return if !canFilter

    previousKey = App.FileFindCommand.keyFor(pattern.slice(0, -1), path)
    results = @get("results.#{previousKey}")
    re = new RegExp(pattern.replace(/./g, (char) -> ".*?#{char}") + ".*?", 'i')
    results = _.filter results, (item) ->
      item.filename.match(re)
    key = App.FileFindCommand.keyFor(pattern, path)
    @set "results.#{key}", results
    @set 'newResults', Date.now()
    true

  incrementIndex: ->
    index = @get 'selectedIndex'
    results = (@get 'currentResults') || []
    @incrementProperty('selectedIndex') if index + 1 < results.length

  decrementIndex: ->
    index = @get 'selectedIndex'
    results = (@get 'currentResults') || []
    @decrementProperty('selectedIndex') if index - 1 >= 0

  selectedFile: (->
    results = @get 'currentResults'
    return if !results
    results.objectAt(@get 'selectedIndex')
  ).property 'currentResults.@each.filename', 'selectedIndex'

  updateSelected: (->
    results = @get 'currentResults'
    return if !results
    selectedIndex = @get 'selectedIndex'
    results.forEach (result, index) ->
      result.set 'selected', index == selectedIndex
  ).observes 'currentResults.@each.filename', 'selectedIndex'

  resetSelected: (->
    @set 'selectedIndex', 0
  ).observes 'newResults'

  # true if results are present.  Unlike emptyResults, it does not distinguish
  # between a completed search with no results and an incomplete search
  anyResults: (->
    results = @get 'currentResults'
    results && results.length != 0
  ).property 'currentResults'

  # true when a search has complted and no results were returned
  emptyResults: (->
    results = @get 'currentResults'
    results && results.length == 0
  ).property 'currentResults'

  status: (-> # use when anyResults is false
    if error = @get('errorMessage')
      return error
    if @get('pattern')?.length > 0
      if @get('emptyResults') then 'No results found' else 'Searching...'
    else
      null # nothing typed, text field placeholder has instructions
  ).property 'currentResults', 'currentKey', 'errorMessage'

  placeholder: (->
    "Search files in #{@get 'prettyPath'}"
  ).property 'prettyPath'

  prettyPath: (->
    path = @get 'basePath'
    if path == '.'
      'all directories'
    else
      if path.slice(-1) == '/' then path else path + '/'
  ).property 'basePath'

  currentResults: (->
    key = @get 'currentKey'
    @get "results.#{key}"
    # cannot observe 'results' directly for new keys, so whenever results are
    # updated, newResults property needs to be touched
  ).property 'newResults', 'currentKey'

  currentKey: (->
    App.FileFindCommand.keyFor @get('currentSearch'), @get('basePath')
  ).property 'currentSearch', 'basePath'

  addResults: (pattern, path, newResults) ->
    results = this.populateResults pattern, path
    _.each newResults.trim().split("\n"), (result) =>
      results.pushObject Em.Object.create(filename: result)
    @set 'newResults', Date.now()

  populateResults: (pattern, path, touch) ->
    key = App.FileFindCommand.keyFor(pattern, path)
    slug = "results.#{key}"
    results = @get slug
    if !results
      @set slug, Ember.A([])
      results = @get slug
    @set('newResults', Date.now()) if touch
    results

  hasResults: (pattern, path) ->
    results = @get("results.#{App.FileFindCommand.keyFor(pattern, path)}")
    results && results?.length != 0

  errorMessage: (->
    switch @get('error')
      when 'NOPATH'
        "Could not find path #{@get 'basePath'}.  Please check if it exists"
      when 'NOBINARY'
        'Please restart your box to enable this feature'
      else
        null
  ).property 'error', 'basePath'

klass.reopenClass
  maxResults: 10
