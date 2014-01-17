AIO.IdeAutopartsController = Em.Controller.extend
  autopartsInstallDialog: null
  autopartsUninstallDialog: null
  autopartsServicesDialog: null

  parts: null # array of AIO.PartsCollection

  partsSocketBinding: Em.Binding.oneWay 'AIO.router.ideController.partsSocket'

  partsSocketDidStartForTheFirstTime: (->
    if @get 'partsSocket.startedFirstTime'
      # make this a delayed request,
      # so it won't slow down
      # loading rest of the IDE.
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
    @set 'autopartsUninstallDialog', null
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

  showAutopartsUninstallDialog: ->
    partsSocket = @get 'partsSocket'
    if partsSocket
      @set 'autopartsUninstallDialog', AIO.AutopartsUninstallDialog.create()

  showAutopartsServicesDialog: ->
    partsSocket = @get 'partsSocket'
    if partsSocket
      @set 'autopartsServicesDialog', AIO.AutopartsServicesDialog.create()

  available: (callback) ->
    if parts = @get 'parts'
      callback parts.rejectProperty('installed')

  installed: (callback) ->
    if parts = @get 'parts'
      callback parts.filterProperty('installed')

  hasStatus: (callback) ->
    if parts = @get 'parts'
      callback parts.filterProperty('status')

  search: (term, callback) ->
    if parts = @get 'parts'
      termRegex = new RegExp term, "i"
      matchingParts = parts.filter (item) ->
        if item.name.match(termRegex) || item.description.match(termRegex)
          return true
      callback matchingParts

  install: (part) ->
    return unless part
    socket = @get 'partsSocket'
    part.set 'processing', true
    part.set 'errorMessage', null

    socket.install part.get('name'), (err, output) =>
      part.set 'processing', false
      if err
        partName = part.get 'name'
        part.set 'errorMessage', "Failed to install \"#{partName}\". Try running `parts install #{partName}` directly from the terminal."
        AIO.util.mixpanel 'Autoparts Install Failed via UI', part: partName, region_id: AIO.get('router.ideController.content.region_id')
      else
        part.set 'installed', true
        # refresh part statuses list
        this._setPartsStatuses()

  uninstall: (part) ->
    return unless part
    socket = @get 'partsSocket'
    part.set 'processing', true
    part.set 'errorMessage', null

    socket.uninstall part.get('name'), (err, output) =>
      part.set 'processing', false
      if err
        partName = part.get 'name'
        part.set 'errorMessage', "Failed to uninstall \"#{partName}\", please try again."
        AIO.util.mixpanel 'Autoparts Uninstall Failed via UI', part: partName, region_id: AIO.get('router.ideController.content.region_id')
      else
        part.set 'installed', false
        part.set 'status', null

  start: (part) ->
    return unless part
    socket = @get 'partsSocket'
    part.set 'processing', true
    part.set 'errorMessage', null

    socket.start part.get('name'), (err, output) =>
      part.set 'processing', false
      if err
        partName = part.get 'name'
        part.set 'errorMessage', "Failed to start \"#{partName}\", please try again."
        AIO.util.mixpanel 'Autoparts Start Failed via UI', part: partName, region_id: AIO.get('router.ideController.content.region_id')
      else
        part.set 'status', 'running'

  stop: (part) ->
    return unless part
    socket = @get 'partsSocket'
    part.set 'processing', true
    part.set 'errorMessage', null

    socket.stop part.get('name'), (err, output) =>
      part.set 'processing', false
      if err
        partName = part.get 'name'
        part.set 'errorMessage', "Failed to stop \"#{partName}\", please try again."
        AIO.util.mixpanel 'Autoparts Stop Failed via UI', part: partName, region_id: AIO.get('router.ideController.content.region_id')
      else
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
