#= require ./base-model

App.BoxTemplate = klass = App.BaseModel.extend
  name: Em.attr()
  image: Em.attr()
  description: Em.attr()
  enabled: Em.attr()
  runtime: Em.attr()

  init: ->
    @_super.apply this, arguments
    @set 'enabled', @get('enabled') ? false

klass.reopenClass
  rootKey: 'box_template'
  collectionKey: 'box_templates'
  url: '/box_templates'
