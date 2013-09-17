AIO.AccountSettingsIndexView = Em.View.extend
  templateName: 'templates/account_settings/index'
  classNames: ['app_page', 'index']
  elementId: 'account_settings_index_view'

  maxN2oBinding: Em.Binding.oneWay 'AIO.currentUser.max_n2o'
  usedN2oBinding: Em.Binding.oneWay 'AIO.currentUser.used_n2o'
  baseN2oBinding: Em.Binding.oneWay 'AIO.currentUser.base_n2o'

  unusedN2o: (->
    @get('maxN2o') - @get('usedN2o')
  ).property 'usedN2o', 'maxN2o'

  resetting_password: false

  didClickPasswordReset: ->
    @get('controller').resetPassword()

  didClickUpdate: ->
    @get('controller').updateProfile()

  didClickChangeCreditCard: ->
    @get('controller').changeCreditCard()

  didClickCancelSubscription: ->
    @get('controller').confirmCancelSubscription()

  didClickChangePlan: ->
    AIO.get('router').transitionTo 'n2o.upgrade'
