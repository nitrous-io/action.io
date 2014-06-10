#= require ./base-model

App.Location = klass = App.BaseModel.extend
  name: Em.attr()
  description: Em.attr()

klass.reopenClass
  rootKey: 'location'
  collectionKey: 'locations'
  url: '/locations'

klass.Collection = Em.ArrayProxy.extend Em.SortableMixin,
  sortProperties: ['name']
