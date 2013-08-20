AIO.BuyN2oDialog = Em.Object.extend
  card: null
  plans: null

  init: ->
    @_super()
    @set 'card', AIO.CreditCard.create()
    @set 'plans', [
      Ember.Object.create { name: "100 N2O ($5.00 per month)", id: 1 }
      Ember.Object.create { name: "250 N2O ($10.00 per month)", id: 2 }
      Ember.Object.create { name: "500 N2O ($15.00 per month)", id: 3 }
    ]
