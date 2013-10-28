AIO.IdeBasicAuthController = Em.Controller.extend
  manageAuthDialog: null

  reset: ->
    @set 'manageAuthDialog', null

  showAuthDialog: ->
    if box = AIO.get 'router.ideController.content'
      @set 'manageAuthDialog', AIO.ManageAuthDialog.create box: box

  updateAuthentication: ->
    if box = AIO.get 'router.ideController.content'
      box.updateAuth (err) =>
        unless err
          @set 'manageAuthDialog', null
