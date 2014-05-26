App.FileFinderDialog = Em.Object.extend
  pattern: null
  basePath: null
  results: null

  selectedIndex: null
  currentSearch: null

  init: ->
    @_super()
    @set 'results', Em.Object.create()
    @set 'selectedIndex', 0

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

  anyResults: (->
    results = @get 'currentResults'
    results && results?.length != 0
  ).property 'currentResults'

  status: (-> # use when currentResults is empty
    if @get('pattern')?.length > 0
      results = @get 'currentResults'
      "Searching..." if !results || results.length == 0
    else
      "Start typing to fuzzy-search for files in #{@get 'prettyPath'}"
  ).property 'currentResults', 'currentKey'

  prettyPath: (->
    path = @get 'basePath' 
    if path == '.' then 'all directories' else path
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
    key = App.FileFindCommand.keyFor(pattern, path)
    slug = "results.#{key}"
    results = @get slug
    if !results
      @set slug, Ember.A([])
      results = @get slug
    _.each newResults.trim().split("\n"), (result) =>
      results.pushObject Em.Object.create(filename: result)
    @set 'newResults', Date.now()

  hasResults: (pattern, path) ->
    results = @get("results.#{App.FileFindCommand.keyFor(pattern, path)}")
    results && results?.length != 0

