describe 'aio.routers.ConsoleRouter', ->
  router = null; request = null

  before ->
    ConsoleRouter = aio.routers.ConsoleRouter
    jasmine.Ajax.useMock()
    $('#jasmine-fixtures').append($('<div id="page_content">'))
    spyOn(ConsoleRouter.prototype, 'fetchBoxes').andCallThrough()
    spyOn(ConsoleRouter.prototype, 'fetchBoxTemplates').andCallThrough()
    router = new ConsoleRouter

  it 'initializes boxes and box templates collections', ->
    expect(aio.app.boxes instanceof aio.collections.Boxes).toBe true
    expect(aio.app.boxTemplates instanceof aio.collections.BoxTemplates).toBe true

  it 'calls fetchBoxes and fetchBoxTemplates', ->
    expect(router.fetchBoxes).toHaveBeenCalled()
    expect(router.fetchBoxTemplates).toHaveBeenCalled()

  describe '#fetchBoxes', ->
    before ->
      spyOn(aio.collections.Boxes.prototype, 'fetch')
      router.fetchBoxes()

    it 'initializes a boxes collection', ->
      expect(aio.app.boxes instanceof aio.collections.Boxes).toBe true

    it 'fetches the collection', ->
      expect(aio.app.boxes.fetch).toHaveBeenCalled()

  describe '#fetchBoxTemplates', ->
    before ->
      spyOn(aio.collections.BoxTemplates.prototype, 'fetch')
      router.fetchBoxTemplates()

    it 'initializes a box templates collection', ->
      expect(aio.app.boxTemplates instanceof aio.collections.BoxTemplates).toBe true

    it 'fetches the collection', ->
      expect(aio.app.boxTemplates.fetch).toHaveBeenCalled()


