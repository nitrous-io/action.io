#= require ./base-model

App.BoxhostPlan = klass = App.BaseModel.extend
  name: Em.attr()
  price: Em.attr(Number)
  interval: Em.attr()
  memory: Em.attr(Number)
  storage: Em.attr(Number)
  box_limit: Em.attr(Number)
  display_order: Em.attr(Number)
  features: Em.attr()

  formattedPrice: (->
    App.util.asCurrency @get('price') / 100
  ).property 'price'

klass.reopenClass
  rootKey: 'boxhost_plan'
  collectionKey: 'boxhost_plans'
  url: '/boxhost_plans'

klass.Collection = Em.ArrayProxy.extend Em.SortableMixin,
  sortProperties: ['display_order']
