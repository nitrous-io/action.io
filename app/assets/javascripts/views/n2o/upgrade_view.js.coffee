AIO.N2oUpgradeView = Em.View.extend
  templateName: 'templates/n2o/upgrade'
  classNames: ['app_page']
  elementId: 'n2o_upgrade_view'

  willInsertElement: ->
    @_super()

    if AIO.get('currentUser.subscription_pending')
      AIO.get('router').transitionTo 'n2o.index'
      Em.run.scheduleOnce 'afterRender', this, ->
        AIO.set 'flashMessage', { type: 'alert-success', text: 'We are still processing your new subscription, you should be receiving an email shortly.' }
      return

    if AIO.get('subscription')?.get 'active'
      AIO.get('router').transitionTo 'n2o.change_plan'
      return

  didClickUpgrade: ->
    @get('controller').upgrade()
