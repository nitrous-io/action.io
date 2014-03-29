App.IdeBasicAuthController = Em.Controller.extend
  manageAuthDialog: null

  reset: ->
    @set 'manageAuthDialog', null

  showAuthDialog: ->
    if box = App.get 'router.ideController.content'
      @set 'manageAuthDialog', App.ManageAuthDialog.create box: box

  updateAuthentication: ->
    if box = App.get 'router.ideController.content'
      box.updateAuth (err) =>
        unless err
          @set 'manageAuthDialog', null
