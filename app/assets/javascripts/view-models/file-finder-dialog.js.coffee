App.FileFinderDialog = Em.Object.extend
  pattern: null
  basePath: null
  results: null

  currentSearch: null
  currentResults: null

  init: ->
    @_super()
    @set 'results', Em.Object.create()
    @set 'currentResults', Ember.A([])

  updateCurrentResults: (->
    @set 'currentResults', @get("results.#{@get('currentKey')}")
  ).observes 'touchCurrentResults'

  touch: ->
    @set 'touchCurrentResults', Date.now()

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
      results.pushObject filename: result
    this.touch()

  hasResults: (pattern, path) ->
    results = @get("results.#{App.FileFindCommand.keyFor(pattern, path)}")
    results && results?.length != 0

