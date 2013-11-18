AIO.IdeAutopartsController = Em.Controller.extend
  manageAutopartsDialog: null

  parts: null # array of AIO.PartsCollection

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
      , 5000)
  ).observes 'partsSocket.startedFirstTime'

  reset: ->
    @set 'manageAutopartsDialog', null
    @set 'parts', null

  showManageAutopartsDialog: ->
    partsSocket = @get 'partsSocket'
    if partsSocket
      @set 'manageAutopartsDialog', AIO.ManageAutopartsDialog.create()

  search: (term, callback) ->
    if allParts = @get 'parts'
      termRegex = new RegExp term, "i"
      matchingParts = allParts.filter (item) ->
        if item.name.match(termRegex) || item.description.match(termRegex)
          return true
      callback matchingParts
    else
      window.setTimeout(=>
        this.search(term, callback)
      , 200)

  installed: (callback) ->
    if allParts = @get 'parts'
      callback allParts.filterProperty('installed')
    else
      window.setTimeout(=>
        this.installed callback
      , 200)

  recommended: (callback) ->
    if allParts = @get 'parts'
      recommendedParts = allParts.filter (p) ->
        _.contains ['mysql', 'meteor', 'the_silver_searcher'], p.name
      callback recommendedParts
    else
      window.setTimeout(=>
        this.installed callback
      , 200)

  install: (name, callback) ->
    socket = @get 'partsSocket'
    socket.install name, (err, output) =>
      if err
        callback err, null
      else
        @get('parts').installed name
        callback null, output

  uninstall: (name) ->
    socket = @get 'partsSocket'
    socket.uninstall name, (err, output) =>
      if err
        callback err, null
      else
        @get('parts').uninstalled name
        callback null, output
