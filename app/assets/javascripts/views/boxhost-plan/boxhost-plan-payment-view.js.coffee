App.BoxhostPlanPaymentView = Em.View.extend
  templateName: 'templates/boxhost-plan/payment'
  classNames: ['app_page', 'payment']
  elementId: 'boxhost_plan_payment_view'

  didInsertElement: ->
    @_super()
    App.util.mixpanel 'Viewed Boxhost Plan Payment'
