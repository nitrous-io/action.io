AIO.AccountSettingsIndexController = Em.ObjectController.extend
  content: null
  verifyPasswordDialog: null

  init: ->
    @_super()

  updateProfile: ->
    @set 'verifyPasswordDialog', AIO.VerifyPasswordDialog.create()

