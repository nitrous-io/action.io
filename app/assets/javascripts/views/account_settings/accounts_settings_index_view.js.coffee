AIO.AccountSettingsIndexView = Em.View.extend
  templateName: 'templates/account_settings/index'
  classNames: ['app_page', 'index']
  elementId: 'account_settings_index_view'

  resetting_password: false

  hasPaidSubscription: (->
    AIO.get('subscription')?.get('active')
  ).property 'AIO.subscription.active'

  hasVisibleBoxes: (->
    AIO.get('router.boxesController.content.length')
  ).property 'AIO.router.boxesController.content'

  didClickPasswordReset: ->
    @get('controller').resetPassword()

  didClickUpdate: ->
    @get('controller').updateProfile()

  didClickChangeCreditCard: ->
    @get('controller').changeCreditCard()

  didClickCancelSubscription: ->
    @get('controller').confirmCancelSubscription()

  didClickChangePlan: ->
    AIO.get('router').transitionTo 'n2o.change_plan'

  didClickDeleteAccount: ->
    if @get 'hasPaidSubscription'
      AIO.set 'flashMessage', { type: 'alert-error', text: 'You must cancel your subscription before deleting your account.' }
    else if @get 'hasVisibleBoxes'
      AIO.set 'flashMessage', { type: 'alert-error', text: 'You must terminate all your boxes before deleting your account.' }
    else
      @get('controller').confirmDeleteAccount()
