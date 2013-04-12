AIO.IdeBasicAuthController = Em.Controller.extend
  manageAuthDialog: null

  reset: ->
    this.hideAuthDialog()

  showAuthDialog: ->
    @set 'manageAuthDialog', AIO.ManageAuthDialog.create()

  updateAuthentication: ->
    @get('manageAuthDialog').updateAuth (err) =>
      this.hideAuthDialog() unless err

  hideAuthDialog: ->
    @set 'manageAuthDialog', null
