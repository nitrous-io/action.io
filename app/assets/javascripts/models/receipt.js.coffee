#= require ./base-model

App.Receipt = klass = App.BaseModel.extend
  period_start: Em.attr()
  period_end: Em.attr()
  total: Em.attr()

  date: (->
    period_start = new Date @get('period_start')
    App.util.strftime '%B %d %Y', period_start
  ).property 'period_start'

  formattedTotal: (->
    total = @get('total') / 100
    App.util.asCurrency total
  ).property 'amount'

  receiptPath: (->
    "/receipts/#{@get 'id'}"
  ).property 'id'

klass.reopenClass
  url: '/receipts'
  collectionKey: 'receipts'
