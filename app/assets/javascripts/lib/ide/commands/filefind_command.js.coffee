App.FileFindCommand = Em.Object.extend
  # separator between search key and data
  dataDelimiter: "!!\n"

  # separator between file pattern and path so that (pattern1, path1) and
  # (pattern2, path2) do not overlap
  searchKeyDelimiter: "\\\\"

  results: null

  init: ->
    @set('results', Em.Object.create())

  bindEvents: (socket) ->
    socket.on 'filefind.commandOutput', (data) =>
      this.onOutput(data)
    socket.on 'filefind.commandError', (data) =>
      this.onError(data)
    socket.on 'filefind.commandComplete', (data) =>
      this.onComplete(data)

  send: (socket, pattern, path, callback) ->
    # used to see if results are relevant to current search
    socket.sendAs 'filefind', 'filefind', pattern, path, =>
      callback(this, this.keyFor(pattern, path))

  keyFor: (pattern, path) ->
    [pattern, path].join(this.searchKeyDelimiter)

  onOutput: (data) ->
    console.log(data)

  onError: (data) ->
    console.log(data)

  onComplete: (data) ->
    console.log("Complete: #{data}")

  parseIdData: (data) ->
    return data.split(this.dataDelimiter)
