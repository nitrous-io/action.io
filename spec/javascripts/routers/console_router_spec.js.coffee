describe 'aio.routers.ConsoleRouter', ->
  router = null
  box = null
  boxTemplate = null

  before ->
    $('#jasmine-fixtures').append($('<div id="page_content">'))
    box = new aio.models.Box
    boxTemplate = new aio.models.BoxTemplate
    router = new aio.routers.ConsoleRouter
      boxes: [box]
      boxTemplates: [boxTemplate]
      regions: ['us-west-1', 'ap-southeast-1']
    Backbone.history.start

  it 'initializes boxes and box templates collections', ->
    expect(aio.app.boxes.models).toEqual [box]
    expect(aio.app.boxTemplates.models).toEqual [boxTemplate]
    expect(aio.app.regions).toEqual ['us-west-1', 'ap-southeast-1']

