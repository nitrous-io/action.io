AIO.N2oUpgradeView = Em.View.extend
  templateName: 'templates/n2o/upgrade'
  classNames: ['app_page']
  elementId: 'n2o_upgrade_view'

  upgradeButtonDisabled: (->
    controller = @get 'controller'

    # Disable when an upgrade is processing
    return true if controller.get('processing')

    # Enable if user changes plans
    return false if controller.get('currentPlan') != controller.get('selectedPlan')

    # Disable if user has subscribed to a current plan
    return true if controller.get('currentPlan')
  ).property 'controller.processing', 'controller.currentPlan', 'controller.selectedPlan'

  didClickUpgrade: ->
    controller = @get 'controller'
    controller.processUpgrade()

  didClickChangeCreditCard: ->
    controller = @get 'controller'
    controller.set 'cardChanged', true
    $('#currentCreditCardDetails').hide()
    $('#addCreditCard').show()
