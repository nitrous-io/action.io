App.IdeFileFinderController = Em.Controller.extend
  needs: ['boxIde', 'ideEditor']

  fileFinderDialog: null

  reset: ->
    @set 'fileFinderDialog', null

  showFindDialog: (location) ->
    if !location?
      location = this.guessLocation(@get('controllers.ideEditor.activeTab.path.absolutePath'))
    @set 'fileFinderDialog', App.FileFinderDialog.create location: location

  startFind: (pattern, location) ->
    location = '.' if not location?.length
    App.util.mixpanel 'Started FileFinder',
      location: location
    if socket = @get('controllers.boxIde.commandSocket')
      socket.filefind pattern, location, (command, searchKey) =>
        console.log(command)
        console.log(searchKey)

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
