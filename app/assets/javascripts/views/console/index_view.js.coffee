aio.views ||= {}
aio.views.console ||= {}

class aio.views.console.IndexView extends Backbone.View
  template: JST['console/index']
  id: 'console-index'

  initialize: ->
    @sidebarView = new aio.views.console.SidebarView
    @loadingIndicatorView = new aio.views.LoadingIndicatorView

  render: ->
    @$el.html(this.template())
    this.$('#console-sidebar').replaceWith(@sidebarView.render().$el)
    $('#page_content').append(@loadingIndicatorView.render().$el)
    this

  showNewBoxView: ->
    newBoxView = new aio.views.console.NewBoxView
    this.$('.console-content').replaceWith(newBoxView.render().$el)

