aio.views.console ||= {}
aio.views.console.boxes ||= {}

class aio.views.console.boxes.TerminalView extends Backbone.View
  template: JST['previous/templates/console/boxes/terminal_view']
  id: 'console-boxes-terminal'
  className: 'console-content'

  render: ->
    @$el.html(this.template(@model.toJSON()))
    this

