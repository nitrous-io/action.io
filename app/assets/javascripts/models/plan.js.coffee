#= require ./base-model

AIO.Plan = klass = AIO.BaseModel.extend
  name: Em.attr()
  price: Em.attr(Number)
  interval: Em.attr()
  highlight: Em.attr()
  display_order: Em.attr(Number)
  n2o_amount: Em.attr(Number)
  features: Em.attr()

  formattedPrice: (->
    price = @get 'price'
    "$#{price.toFixed(2)}"
  ).property 'price'

klass.reopenClass
  adapter: null
  rootKey: 'plan'

  personalPlans: null
  teamPlans: null

klass.Collection = Em.ArrayProxy.extend Em.SortableMixin,
  sortProperties: ['display_order']
