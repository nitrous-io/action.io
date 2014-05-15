App.IdeFindInProjectController = Em.Controller.extend
  needs: ['boxIde', 'ideEditor']

  findInProjectDialog: null

  reset: ->
    @set 'findInProjectDialog', null

  showFindDialog: ->
    defaultLocation = this.guessLocation(@get('controllers.ideEditor.activeTab.path.absolutePath'))
    @set 'findInProjectDialog', App.FindInProjectDialog.create location: defaultLocation

  startFind: (term, location, options) ->
    location = '.' if !location
    if socket = @get('controllers.boxIde.commandSocket')
      socket.search term, location, options, (tabId) =>
        editorController = @get('controllers.ideEditor')
        doc = editorController.createTab({ term: term, path: location }, App.SearchResults)
        socket.set "resultDocuments.#{tabId}", doc
    this.reset()

  # try to pick a sensible default search root
  guessLocation: (location) ->
    homedir = null # search will default to homedir if null; this displays the placeholder text we want for the default

    return homedir if not location?.length
    parts = location.split('/')
    in_workspace = parts[0] == 'workspace'
    switch
      when parts.length == 1
        if in_workspace then 'workspace' else homedir
      when parts.length == 2
        parts[0]
      else
        if in_workspace
          [parts[0], parts[1]].join('/')
        else
          parts[0]
