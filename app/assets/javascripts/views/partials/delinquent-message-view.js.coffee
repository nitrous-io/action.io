AIO.DelinquentMessageView = Em.View.extend
  templateName: 'templates/partials/delinquent_message'

  didClickChangeCreditCard: ->
    AIO.get('router').transitionTo 'accountSettings.index'
    Em.run.scheduleOnce 'afterRender', this, ->
      AIO.get('router.accountSettingsIndexController').changeCreditCard()
