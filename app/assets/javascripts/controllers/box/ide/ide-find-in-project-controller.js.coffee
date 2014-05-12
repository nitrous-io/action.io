App.IdeFindInProjectController = Em.Controller.extend
  needs: ['boxIde']

  findInProjectDialog: null

  reset: ->
    @set 'findInProjectDialog', null

  showFindDialog: ->
    @set 'findInProjectDialog', App.FindInProjectDialog.create()

  startFind: (term, location) ->
    if boxIde = @get('controllers.boxIde')
      boxIde.get('commandSocket').search term, location, -> {}
    this.reset()
