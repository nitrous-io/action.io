untitledCount = 0

App.Document = Em.Object.extend
  active: false
  focused: false
  content: ''
  path: null
  contentType: null
  clean: true

  searchResults: []
  searchFilesCount: 0
  searchMatchCount: 0

  findTrigger: null
  findNextTrigger: null
  findPrevTrigger: null
  replaceTrigger: null
  replaceAllTrigger: null

  foldCodeTrigger: null
  unfoldCodeTrigger: null
  toggleCommentTrigger: null

  title: (->
    @get('path.name') || "Untitled #{untitledCount += 1}"
  ).property 'path.name'

  isImageFile: (->
    @get('contentType')?.match /^image/
  ).property 'contentType'

  isSearchResult: (->
    @get('contentType') == 'search-results'
  ).property 'contentType'

  tooltip: (->
    @get('path.absolutePath') || @get('title')
  ).property 'path.absolutePath'

  addSearchResults: (data) ->
    lines = data.split("\n")
    # parse ackmate format
    buffer = ''
    emptyResult = ->
      filename: ''
      lines: []
    currentResult = emptyResult()
    flush = =>
      @get('searchResults').pushObject(currentResult)
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

