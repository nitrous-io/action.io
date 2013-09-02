AIO.AccountSettingsIndexController = Em.ObjectController.extend
  content: null

  init: ->
    @_super()

  updateProfile: ->
    record = @get 'content'
    record.set 'errors', null
    record.updateInfo()
          .done ->
            AIO.set 'flashMessage', { type: 'notice', text: 'You updated your account successfully.' }

