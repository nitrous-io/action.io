#= require ./tab-content

App.SearchResults = App.TabContent.extend
  isSearchTab: true

  content: ''
  path: null
  contentType: 'search-results'

  term: null
  status: 'Searching...'
  results: null
  fileCount: 0
  matchCount: 0

  init: ->
    @_super()
    @set 'results', Ember.A([])

  title: (->
    if term = @get('term')
      termTitle = if term.length > 6 then term.slice(0, 6) + "..." else term
      "Search results: '#{termTitle}'"
    else
      "Searching..."
  ).property 'term'

  tooltip: (->
    "Search results: '#{@get('term')}'"
  ).property 'term'

  addSearchResults: (data) ->
    lines = data.split("\n")
    # parse ackmate format
    buffer = ''
    emptyResult = ->
      filename: ''
      lines: []
    currentResult = emptyResult()
    flush = =>
      @get('results').pushObject(currentResult)
      currentResult = emptyResult()

    _.each lines, (rawLine) =>
      switch
        # ag --ackmate format
        # :filename.ext           Filename of match
        when rawLine[0] == ':'
          if currentResult.filename != ''
            flush()
          currentResult.filename = rawLine.slice(1)
        when rawLine == ''
          # no-op
        else
          currentResult.lines.push this.parseResultLine(rawLine)

    flush()

  parseResultLine: (rawLine) ->
    # ag --ackmate format
    # 123:linetext            no matches on line 123, just context
    # 123;45 6:linetext       single match on line 123, col 45, match is 6 chars long
    # 123;45 6,78 9:linetext  multiple matches on line 123, col 45 6 chars, col 78 9 chars
    [metadata, lineTextParts...] = rawLine.split(':')
    [lineNumber, matchInfo] = metadata.split(';')

    parsedLine =
      lineText: lineTextParts.join(':')
      lineNumber: lineNumber
      matches: if matchInfo then matchInfo.split(',') else []

