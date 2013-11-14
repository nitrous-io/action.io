AIO.InstalledPartsCollection = Em.ArrayProxy.extend
  content: null

AIO.AllPartsCollection = Em.ArrayProxy.extend
  content: null

AIO.IdeAutopartsController = Em.Controller.extend
  manageAutopartsDialog: null

  allParts: null # array of AIO.AllPartsCollection
  installedParts: null # array of AIO.InstalledPartsCollection

  partsSocketBinding: Em.Binding.oneWay 'AIO.router.ideController.partsSocket'
  partsSocketReadyBinding: Em.Binding.oneWay 'partsSocket.started'
  partsSocketNotReady: (->
    !@get 'partsSocketReady'
  ).property 'partsSocketReady'

  partsSocketDidStartForTheFirstTime: (->
    if @get 'partsSocket.startedFirstTime'
      # make a delayed request,
      # so it won't slow down
      # initalization of rest of the IDE
      window.setTimeout(=>
        socket = @get 'partsSocket'
        socket.list (err, installedParts) =>
          unless err
            @set 'installedParts', AIO.InstalledPartsCollection.create(content: Em.A(installedParts))
        socket.search '', (err, allParts) =>
          unless err
            @set 'allParts', AIO.AllPartsCollection.create(content: Em.A(allParts))
      , 5000)
  ).observes 'partsSocket.startedFirstTime'

  reset: ->
    @set 'manageAutopartsDialog', null
    @set 'matchingParts', null
    @set 'allParts', null

  showManageAutopartsDialog: ->
    partsSocket = @get 'partsSocket'
    if partsSocket
      @set 'manageAutopartsDialog', AIO.ManageAutopartsDialog.create()

  install: (name, callback) ->
    socket = @get 'partsSocket'
    socket.install name, (err, output) =>
      if err
        callback err, null
      else
        #todo: add to installedParts
        callback null, output

  uninstall: (name) ->
    socket = @get 'partsSocket'
    socket.uninstall name, (err, output) =>
      if err
        callback err, null
      else
        #todo: remove from installedParts
        callback null, output

  search: (term, callback) ->
    termRegex = new RegExp term, "i"
    allParts = @get 'allParts'
    matchingParts = allParts.filter (item) ->
      if item.name.match(termRegex) || item.description.match(termRegex)
        return true
    callback matchingParts
