describe 'aio.routers.ConsoleRouter', ->
  router = null

  before ->
    $('#jasmine-fixtures').append($('<div id="page_content">'))
    router = new aio.routers.ConsoleRouter

