aio.views.console ||= {}

class aio.views.console.SidebarBoxView extends Backbone.View
  template: JST['console/sidebar_box']
  tagName: 'li'

  render: ->
    @$el.html(this.template(@model.toJSON()))
    this

