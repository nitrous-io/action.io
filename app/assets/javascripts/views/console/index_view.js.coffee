aio.views ||= {}
aio.views.console ||= {}

class aio.views.console.IndexView extends Backbone.View
  template: JST['console/index']

  render: ->
    @$el.html(this.template())
    this

