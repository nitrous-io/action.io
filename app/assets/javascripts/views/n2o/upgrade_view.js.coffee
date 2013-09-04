AIO.N2oUpgradeView = Em.View.extend
  templateName: 'templates/n2o/upgrade'
  classNames: ['app_page']
  elementId: 'n2o_upgrade_view'

  didInsertElement: ->
    # make form fields behave as payment fields
    $('#card_number').payment 'formatCardNumber'
    $('#card_expiration').payment 'formatCardExpiry'
    $('#card_cvc').payment 'formatCardCVC'
    $('#card_billing_zip').payment 'restrictNumeric'

  didClickUpgrade: ->
    controller = @get 'controller'
    controller.processUpgrade()

  didClickChangeCreditCard: ->
    controller = @get 'controller'
    controller.set 'chaningeCard', true
    $('#currentCreditCardDetails').hide()
    $('#addCreditCard').show()
