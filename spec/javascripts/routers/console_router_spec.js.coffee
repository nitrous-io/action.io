describe 'aio.routers.ConsoleRouter', ->
  [router, box, boxTemplate, publicKey] = []

  before ->
    $('#jasmine-fixtures').append($('<div id="page_content">'))
    box = new aio.models.Box
    boxTemplate = new aio.models.BoxTemplate
    publicKey = new aio.models.PublicKey
    router = new aio.routers.ConsoleRouter
      boxes: [box]
      boxTemplates: [boxTemplate]
      publicKeys: [publicKey]
      regions: ['us-west-1', 'ap-southeast-1']
    Backbone.history.start()

  it 'initializes boxes and box templates collections', ->
    expect(aio.app.boxes.models).toEqual [box]
    expect(aio.app.boxTemplates.models).toEqual [boxTemplate]
    expect(aio.app.publicKeys.models).toEqual [publicKey]
    expect(aio.app.regions).toEqual ['us-west-1', 'ap-southeast-1']

