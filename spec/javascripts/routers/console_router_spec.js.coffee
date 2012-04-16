describe 'aio.routers.ConsoleRouter', ->
  [router, box, boxTemplate, publicKey, region] = []

  before ->
    $('#jasmine-fixtures').append($('<div id="page_content">'))
    box = new aio.models.Box
    boxTemplate = new aio.models.BoxTemplate
    publicKey = new aio.models.PublicKey
    region = new aio.models.Region
    router = new aio.routers.ConsoleRouter
      boxes: [box]
      boxTemplates: [boxTemplate]
      publicKeys: [publicKey]
      regions: [region]
    Backbone.history.start()

  it 'initializes boxes and box templates collections', ->
    expect(aio.app.boxes.models).toEqual [box]
    expect(aio.app.boxTemplates.models).toEqual [boxTemplate]
    expect(aio.app.publicKeys.models).toEqual [publicKey]
    expect(aio.app.regions.models).toEqual [region]

