AIO.AccountSettingsIndexView = Em.View.extend
  templateName: 'templates/account_settings/index'
  classNames: ['app_page', 'index']
  elementId: 'account_settings_index_view'

  resetting_password: false

  didClickPasswordReset: ->
    @get('controller').resetPassword()

  didClickUpdate: ->
    @get('controller').updateProfile()

  didClickChangeCreditCard: ->
    @get('controller').changeCreditCard()

  didClickCancelSubscription: ->

  didClickChangePlan: ->
    AIO.get('router').transitionTo 'n2o.upgrade'
