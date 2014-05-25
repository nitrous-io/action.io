App.IdeFileFinderController = Em.Controller.extend
  needs: ['boxIde', 'ideEditor']

  fileFinderDialog: null

  reset: ->
    @set 'fileFinderDialog', null

  showFindDialog: (path) ->
    if !path?
      path = this.guessPath(@get('controllers.ideEditor.activeTab.path.absolutePath'))
    @set 'fileFinderDialog', App.FileFinderDialog.create basePath: path
    App.util.mixpanel 'Started FileFinder',
      basePath: path

  startFind: (pattern, path) ->
    dialog = @get 'fileFinderDialog'
    socket = @get('controllers.boxIde.commandSocket')
    return if !dialog || !socket

    path = '.' if not path?.length

    if dialog.hasResults(pattern, path)?
      dialog.touch()
    else
      socket.filefind dialog, pattern, path, (command, searchKey) =>

  closeFindDialog: ->
    this.reset()

  # try to pick a sensible default search root
  guessPath: (path) ->
    homedir = '.'

    return homedir if not path?.length
    parts = path.split('/')
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
