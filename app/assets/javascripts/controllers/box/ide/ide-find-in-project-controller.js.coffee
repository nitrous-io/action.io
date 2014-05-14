App.IdeFindInProjectController = Em.Controller.extend
  needs: ['boxIde', 'ideEditor']

  findInProjectDialog: null

  reset: ->
    @set 'findInProjectDialog', null

  showFindDialog: ->
    @set 'findInProjectDialog', App.FindInProjectDialog.create()

  startFind: (term, location, options) ->
    if socket = @get('controllers.boxIde.commandSocket')
      socket.search term, location, options, (tabId) =>
        editorController = @get('controllers.ideEditor')
        doc = editorController.createTab({ term: term, path: location }, App.SearchResults)
        socket.set "resultDocuments.#{tabId}", doc
    this.reset()
