AIO.IdeAutopartsController = Em.Controller.extend
  manageDialog: null
  parts: null # array of AIO.PartsCollection
  processing: false
  processingPart: null
  partsSocketBinding: Em.Binding.oneWay 'AIO.router.ideController.partsSocket'

  partsSocketDidStartForTheFirstTime: (->
    if @get 'partsSocket.startedFirstTime'
      # make this a delayed request,
      # so it won't slow down
      # loading rest of the IDE.
      window.setTimeout _.bind(@refresh, this), 5000
  ).observes 'partsSocket.startedFirstTime'

  partSocketDisconnected: (->
    unless @get 'partsSocket.started'
      this.reset()
  ).observes 'partsSocket.started'

  partsChangedFromWebhook: (->
    this.refresh()
  ).observes 'AIO.partsChanged'

  refresh: ->
    socket = @get 'partsSocket'
    socket.listAll (err, parts) =>
      unless err
        @set 'parts', AIO.PartsCollection.createWithModels(parts)
        this._setPartsStatuses()

  reset: ->
    @set 'manageDialog', null
    @set 'parts', null
    @set 'processing', false
    @set 'processingPart', null

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

  showManageDialog: ->
    partsSocket = @get 'partsSocket'
    if partsSocket
      @set 'manageDialog', AIO.ManageAutopartsDialog.create()

  all: (callback) ->
    if parts = @get 'parts'
      callback parts

  installed: (callback) ->
    if parts = @get 'parts'
      callback parts.filterProperty('installed')

  hasStatus: (callback) ->
    if parts = @get 'parts'
      callback parts.filterProperty('status')

  search: (term, onlyInstalled, callback) ->
    parts = @get 'parts'
    return callback({}) unless parts

    if onlyInstalled
      parts = parts.filterProperty('installed')

    # return empty hash if parts doesnt exist
    return callback({}) unless parts

    # return all parts if the term is blank
    return callback(parts) unless term?.length

    termRegex = new RegExp term, "i"
    matchingParts = parts.filter (item) ->
      if item.name.match(termRegex) || item.description.match(termRegex)
        return true

    unless onlyInstalled && matchingParts.length
      AIO.util.mixpanel 'Autoparts Search Failed via UI', term: term

    callback matchingParts

  install: (part) ->
    return unless part
    socket = @get 'partsSocket'
    @set 'processing', true
    @set 'processingPart', part

    outputStream = socket.get('outputStream')
    outputStream.reset()

    socket.install part.get('name')

    outputStream.set 'onComplete', =>
      part.set 'installed', true
      # refresh part statuses list
      this._setPartsStatuses()

  uninstall: (part) ->
    return unless part
    socket = @get 'partsSocket'
    @set 'processing', true
    @set 'processingPart', part

    outputStream = socket.get('outputStream')
    outputStream.reset()

    socket.uninstall part.get('name')

    outputStream.set 'onComplete', =>
      part.set 'installed', false
      part.set 'status', null

  start: (part) ->
    return unless part
    socket = @get 'partsSocket'
    @set 'processing', true
    @set 'processingPart', part

    outputStream = socket.get('outputStream')
    outputStream.reset()

    socket.start part.get('name')

    outputStream.set 'onComplete', =>
      part.set 'status', 'running'

  stop: (part) ->
    return unless part
    socket = @get 'partsSocket'
    @set 'processing', true
    @set 'processingPart', part

    outputStream = socket.get('outputStream')
    outputStream.reset()

    socket.stop part.get('name')

    outputStream.set 'onComplete', =>
      part.set 'status', 'stopped'

  _setPartsStatuses: ->
    if @get('noPartsInstalled')
      return

    socket = @get 'partsSocket'
    socket.status null, (err, services) =>
      unless err
        parts = @get('parts')
        _.each services, (service) ->
          parts.setPropertyOn service.name, 'status', service.status
