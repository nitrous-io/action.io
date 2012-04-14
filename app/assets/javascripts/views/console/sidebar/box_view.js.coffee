aio.views.console ||= {}
aio.views.console.sidebar ||= {}

class aio.views.console.sidebar.BoxView extends Backbone.View
  template: JST['console/sidebar/box_view']
  tagName: 'li'

  initialize: ->
    @model.on('change', this.render, this)

  render: ->
    @$el.html(this.template(@model.toJSON()))
    this

