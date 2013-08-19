AIO.BuyN2oDialogView = AIO.IdeModalDialogView.extend
  templateName: 'templates/n2o/buy_n2o_dialog'
  elementId: 'buy_n2o_dialog_view'
  contentBinding: 'controller.buyN2oDialog' # N2oBonusController

  plans: [
    Ember.Object.create {name: "100 N2O ($5.00 per month)", id: 1}
    Ember.Object.create {name: "250 N2O ($10.00 per month)", id: 2}
    Ember.Object.create {name: "500 N2O ($15.00 per month)", id: 3}
  ]

  didInsertElement: ->

  didClickBuy: ->
