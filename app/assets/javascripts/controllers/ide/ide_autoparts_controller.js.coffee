AIO.IdeAutopartsController = Em.Controller.extend
  autopartsInstallDialog: null
  autopartsRemoveDialog: null
  autopartsServicesDialog: null

  parts: null # array of AIO.PartsCollection
  partStatuses: null # array of AIO.PartsCollection

  partsSocketBinding: Em.Binding.oneWay 'AIO.router.ideController.partsSocket'

  partsSocketDidStartForTheFirstTime: (->
    if @get 'partsSocket.startedFirstTime'
      # make a delayed request,
      # so it won't slow down
      # initalization of rest of the IDE
      window.setTimeout(=>
        socket = @get 'partsSocket'
        socket.listAll (err, parts) =>
          unless err
            @set 'parts', AIO.PartsCollection.createWithModels(parts)
            this._setPartsStatuses()
      , 5000)
  ).observes 'partsSocket.startedFirstTime'

  reset: ->
    @set 'autopartsInstallDialog', null
    @set 'autopartsRemoveDialog', null
    @set 'autopartsServicesDialog', null
    @set 'parts', null

  noPartsInstalled: (->
    if parts = @get('parts')
      parts.filterProperty('installed').length == 0
    else
      true
  ).property 'parts.@each.installed'

  noPartsStatuses: (->
    if parts = @get('parts')
      parts.filterProperty('status').length == 0
    else
      true
  ).property 'parts.@each.status'

  showAutopartsInstallDialog: ->
    partsSocket = @get 'partsSocket'
    if partsSocket
      @set 'autopartsInstallDialog', AIO.AutopartsInstallDialog.create()

  showAutopartsRemoveDialog: ->
    partsSocket = @get 'partsSocket'
    if partsSocket
      @set 'autopartsRemoveDialog', AIO.AutopartsRemoveDialog.create()

  showAutopartsServicesDialog: ->
    partsSocket = @get 'partsSocket'
    if partsSocket
      @set 'autopartsServicesDialog', AIO.AutopartsServicesDialog.create()

  available: (callback) ->
    this._loadParts (parts) ->
      callback parts.rejectProperty('installed')

  installed: (callback) ->
    this._loadParts (parts) ->
      callback parts.filterProperty('installed')

  hasStatus: (callback) ->
    this._loadParts (parts) ->
      callback parts.filterProperty('status')

  search: (term, callback) ->
    this._loadParts (parts) ->
      termRegex = new RegExp term, "i"
      matchingParts = parts.filter (item) ->
        if item.name.match(termRegex) || item.description.match(termRegex)
          return true
      callback matchingParts

  install: (name, callback) ->
    socket = @get 'partsSocket'
    socket.install name, (err, output) =>
      if err
        callback "Failed install package. To install manually: run `parts install #{name}` in the terminal.", null
      else
        @get('parts').installed name
        # refresh part statuses list
        this._setPartsStatuses()
        callback null

  uninstall: (name, callback) ->
    socket = @get 'partsSocket'
    socket.uninstall name, (err, output) =>
      if err
        callback "Error uninstalling package, please try again.", null
      else
        @get('parts').uninstalled name
        callback null

  start: (name, callback) ->
    socket = @get 'partsSocket'
    socket.start name, (err, output) =>
      if err
        callback "Error in starting package, please try again", null
      else
        @get('parts').started name
        callback null

  stop: (name, callback) ->
    socket = @get 'partsSocket'
    socket.stop name, (err, output) =>
      if err
        callback "Error in stopping package, please try again", null
      else
        @get('parts').stopped name
        callback null

  _setPartsStatuses: ->
    if @get('noPartsInstalled')
      return

    socket = @get 'partsSocket'
    socket.status null, (err, services) =>
      unless err
        parts = @get('parts')
        _.each services, (service) ->
          parts.setPropertyOn service.name, 'status', service.status

  _loadParts: (callback) ->
    if parts = @get 'parts'
      callback(parts)
    else
      window.setTimeout(=>
        this._loadParts callback
      , 200)


