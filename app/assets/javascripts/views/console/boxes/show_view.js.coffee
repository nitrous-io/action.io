aio.views.console ||= {}
aio.views.console.boxes ||= {}

class aio.views.console.boxes.ShowView extends Backbone.View
  template: JST['console/boxes/show_view']
  id: 'console-boxes-show'
  className: 'console-content'

  initialize: ->
    @model.on('change', this.render, this)

  render: ->
    @$el.html(this.template(@model.toJSON()))
    this

