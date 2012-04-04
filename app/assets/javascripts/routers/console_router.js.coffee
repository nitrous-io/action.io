aio.routers ||= {}

class aio.routers.ConsoleRouter extends Backbone.Router
  initialize: ->

  routes:
    '': 'index'

  index: ->
    @view = new aio.views.console.IndexView
    this.renderView()

  renderView: ->
    $('#page_content').empty().append(@view.render().$el)

