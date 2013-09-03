AIO.AccountSettingsIndexController = Em.ObjectController.extend
  content: null
  resetting_password: false
  password_reset_done: false

  init: ->
    @_super()

  billingProfile: (->
    AIO.currentUser.get 'billing_profile'
  ).property 'AIO.currentUser'

  currentPlan: (->
    if billingProfile = @get 'billingProfile'
      activeSubscription = _.find billingProfile.subscriptions, (subscription) ->
        subscription.state == 'active'
      activeSubscription.subscription_plan.name
  ).property 'billingProfile'

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

