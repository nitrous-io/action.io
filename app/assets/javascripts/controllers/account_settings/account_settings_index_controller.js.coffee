AIO.AccountSettingsIndexController = Em.ObjectController.extend
  content: null
  verifyPasswordDialog: null

  init: ->
    @_super()

  verifyPassword: ->
    content = @get 'content'
    content.set 'current_password', null
    @set 'verifyPasswordDialog', AIO.VerifyPasswordDialog.create()

  updateProfile: ->
    record = @get 'content'
    record.updateInfo()
          .done ->
            # show a flash message
            console.log 'successfully saved'
