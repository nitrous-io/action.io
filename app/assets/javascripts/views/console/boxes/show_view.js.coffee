aio.views ||= {}
aio.views.console ||= {}
aio.views.console.boxes ||= {}

class aio.views.console.boxes.ShowView extends Backbone.View
  template: JST['console/boxes/show']
  id: 'console-boxes-show'
  className: 'console-content'

  render: ->
    @$el.html(this.template(@model.toJSON()))
    this

