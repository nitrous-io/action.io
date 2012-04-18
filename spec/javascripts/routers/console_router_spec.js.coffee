describe 'aio.routers.ConsoleRouter', ->
  [router, box, boxTemplate, publicKey, region, mockChannel] = []

  before ->
    aio.app.pusher = new Pusher('')
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
      userId: 123
    Backbone.history.start()

  it 'initializes boxes and box templates collections', ->
    expect(aio.app.boxes.models).toEqual [box]
    expect(aio.app.boxTemplates.models).toEqual [boxTemplate]
    expect(aio.app.publicKeys.models).toEqual [publicKey]
    expect(aio.app.regions.models).toEqual [region]
    expect(aio.app.userId).toEqual 123

  it 'subscribes to "private-user-<USER ID>" channel', ->
    expect(router.channel instanceof Pusher.Channel).toBe true
    expect(router.channel.name).toEqual 'private-user-123'

