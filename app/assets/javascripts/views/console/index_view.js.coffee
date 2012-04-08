aio.views ||= {}
aio.views.console ||= {}

class aio.views.console.IndexView extends Backbone.View
  template: JST['console/index']
  id: 'console-index_view'

  render: ->
    @$el.html(this.template())
    this

