AIO.N2oChangePlanView = Em.View.extend
  templateName: 'templates/n2o/change_plan'
  classNames: ['app_page']
  elementId: 'n2o_change_plan_view'

  willInsertElement: ->
    @_super()

    if AIO.get('currentUser.subscription_pending')
      AIO.get('router').transitionTo 'n2o.index'
      Em.run.scheduleOnce 'afterRender', this, ->
        AIO.set 'flashMessage', { type: 'alert-success', text: 'We are still processing your new subscription, you should be receiving an email shortly.' }
      return

    if AIO.get('currentUser.isDelinquent')
      AIO.get('router').transitionTo 'accountSettings.index'
      return

  changePlanDisabled: (->
    controller = @get 'controller'

    # Disable when processing
    return true if controller.get('processing')

    # Enable only if user changes plans
    return controller.get('currentPlan') == controller.get('selectedPlan')
  ).property 'controller.processing', 'controller.currentPlan', 'controller.selectedPlan'

  didClickChangePlan: ->
    controller = @get 'controller'
    controller.changePlan()

  didClickChangeCreditCard: ->
    @get('controller').changeCreditCard()
