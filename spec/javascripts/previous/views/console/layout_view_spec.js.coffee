describe 'aio.views.console.LayoutView', ->
  view = null

  before ->
    view = new aio.views.console.LayoutView
    $('#jasmine-fixtures').append(view.render().$el)

