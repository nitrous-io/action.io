App.N2oUpgradeView = Em.View.extend
  templateName: 'templates/n2o/upgrade'
  classNames: ['app_page']
  elementId: 'n2o_upgrade_view'

  willInsertElement: ->
    @_super()

    if App.get('currentUser.subscription_pending')
      App.get('router').transitionTo 'n2o.index'
      Em.run.scheduleOnce 'afterRender', this, ->
        App.set 'flashMessage', { type: 'alert-success', text: 'We are still processing your new subscription, you should be receiving an email shortly.' }
      return

    if App.get('subscription')?.get 'active'
      App.get('router').transitionTo 'n2o.change_plan'
      return

    if App.get('currentUser.isDelinquent')
      App.get('router').transitionTo 'accountSettings.index'
      return

  didClickUpgrade: ->
    @get('controller').upgrade()

  formattedDiscount: (->
    "-$#{@get('controller.discount').toFixed(2)}"
  ).property 'controller.discount'

  formattedTotal: (->
    "$#{@get('controller.total').toFixed(2)}"
  ).property 'controller.total'
