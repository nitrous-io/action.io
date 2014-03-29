App.DelinquentMessageView = Em.View.extend
  templateName: 'templates/partials/delinquent-message'

  didClickChangeCreditCard: ->
    App.get('router').transitionTo 'accountSettings.index'
    Em.run.scheduleOnce 'afterRender', this, ->
      App.get('router.accountSettingsIndexController').changeCreditCard()
