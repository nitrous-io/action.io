#= require ./tab-content

App.SearchResults = App.TabContent.extend
  isSearchTab: true

  content: ''
  path: null
  contentType: 'search-results'

  term: null
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

  status: (->
    if @get('matchCount') == 0 && @get('fileCount') == 0
      return 'Searching...'
    "#{@get('matchCount')} matches in #{@get('fileCount')} files for '#{@get('term')}'"
  ).property 'fileCount', 'matchCount', 'term'

  addSearchResults: (data) ->
    lines = data.split("\n")
    # parse ackmate format
    buffer = ''
    emptyResult = ->
      filename: ''
      lines: []
      matchCount: 0
    currentResult = emptyResult()
    flush = =>
      @get('results').pushObject(currentResult)
      @incrementProperty('fileCount')
      @incrementProperty('matchCount', currentResult.matchCount)
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
          [line, matchCount] = this.parseResultLine(rawLine)
          currentResult.matchCount += matchCount
          currentResult.lines.push line

    flush()

  parseResultLine: (rawLine) ->
    # ag --ackmate format
    # 123:linetext            no matches on line 123, just context
    # 123;45 6:linetext       single match on line 123 byte 45, match is 6 bytes long
    # 123;45 6,78 9:linetext  multiple matches on line 123: byte 45 6 bytes long, byte 78 9 bytes long
    # NOTE: column and length numbers are *byte* count
    [metadata, lineTextParts...] = rawLine.split(':')
    [lineNumber, matchInfo] = metadata.split(';')

    matches = if matchInfo then matchInfo.split(',') else []

    lineText = lineTextParts.join(':')
    if lineText == ''
      return [{ lineParts: [], lineNumber: lineNumber}, 0]

    lineUtf8 = unescape(encodeURIComponent(lineText))
    lineBytes = (lineUtf8.charCodeAt(i) for i in [0..lineUtf8.length-1])

    lineParts = []

    pushBytes = (bytes, isMatch) ->
      if bytes.length > 0
        lineParts.push
          text: decodeURIComponent(escape(String.fromCharCode.apply(null, bytes)))
          match: isMatch

    currentIndex = 0
    _.each matches, (matchData) ->
      # each iteration through the loop adds at most 2 lineParts -- everything
      # up to the match, and the match itself
      [startIndex, matchLength] = _.map matchData.split(' '), (s) -> parseInt(s)
      partBytes = lineBytes.slice(currentIndex, startIndex)
      pushBytes(partBytes, false)
      partBytes = lineBytes.slice(startIndex, startIndex + matchLength)
      pushBytes(partBytes, true)
      currentIndex = startIndex + matchLength
    # last unmatched fragment
    partBytes = lineBytes.slice(currentIndex)
    pushBytes(partBytes, false)

    return [{ lineParts: lineParts, lineNumber: lineNumber}, matches.length]
