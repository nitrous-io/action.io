AIO.N2oUpgradeView = Em.View.extend
  templateName: 'templates/n2o/upgrade'
  classNames: ['app_page']
  elementId: 'n2o_upgrade_view'

  didClickUpgrade: ->
    controller = @get 'controller'
    controller.processUpgrade()

  didClickChangeCreditCard: ->
    controller = @get 'controller'
    controller.set 'changingCard', true
    $('#currentCreditCardDetails').hide()
    $('#addCreditCard').show()
