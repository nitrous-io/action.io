AIO.AccountSettingsIndexController = Em.ObjectController.extend
  content: null
  resetting_password: false
  password_reset_done: false

  init: ->
    @_super()

  currentPlanName: (->
    billingProfile = AIO.get 'billingProfile'
    activeSubscriptionPlan = billingProfile.get 'activeSubscriptionPlan'
    activeSubscriptionPlan.name
  ).property 'AIO.billingProfile'

  resetPassword: ->
    record = @get 'content'
    record.resetPassword()
          .done ->
            AIO.set 'flashMessage', { type: 'notice', text: 'You should receive an email with instructions to reset the password.' }

  updateProfile: ->
    record = @get 'content'
    record.set 'errors', null
    record.updateInfo()
          .done ->
            AIO.set 'flashMessage', { type: 'notice', text: 'You updated your account successfully.' }

