aio.views ||= {}
aio.views.console ||= {}

class aio.views.console.LayoutView extends Backbone.View
  template: JST['console/layout']
  id: 'console-layout'

  initialize: ->
    @sidebarView = new aio.views.console.SidebarView

  render: ->
    @$el.html(this.template())
    this.$('#console-sidebar').replaceWith(@sidebarView.render().$el)
    this

  showContentView: (view) ->
    this.$('.console-content').replaceWith(view.render().$el)

