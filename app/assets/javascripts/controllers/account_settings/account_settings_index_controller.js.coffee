AIO.AccountSettingsIndexController = Em.ObjectController.extend
  content: null
  resettingPassword: false

  init: ->
    @_super()

  resetPassword: ->
    record = @get 'content'
    @set 'resettingPassword', true
    record.resetPassword()
          .done ->
            AIO.set 'flashMessage', { type: 'notice', text: 'You should receive an email with instructions to reset the password.' }
          .always ->
            @set 'resettingPassword', false

  updateProfile: ->
    record = @get 'content'
    record.set 'errors', null
    record.updateInfo()
          .done ->
            AIO.set 'flashMessage', { type: 'notice', text: 'You updated your account successfully.' }

