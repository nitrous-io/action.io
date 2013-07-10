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
    record.set 'errors', null
    record.updateInfo()
          .done ->
            AIO.set 'flashMessage', { type: 'notice', text: 'You updated your account successfully.' }

