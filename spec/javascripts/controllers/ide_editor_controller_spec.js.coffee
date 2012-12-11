#= require spec_helper

describe 'AIO.IdeEditorController', ->
  controller = undefined
  beforeEach ->
    controller = AIO.get("router.ideEditorController")
    controller.initialize()

  afterEach -> controller.reset()

  describe '#initialize', ->
    beforeEach ->
      box = new AIO.Box()
      box.set "id", 123
      Em.run -> AIO.set("router.ideController.content", box)

    it 'fetches list of opened documents', ->
      sandbox.spy controller, "findAll"
      Em.run -> controller.initialize()
      expect(controller.findAll).to.have.been.called

    it 'activates the first document', ->
      server.respondWith 'GET', '/boxes/123/documents', [
        200
        { 'Content-Type': 'application/json; charset=utf-8' }
        JSON.stringify({documents: [
          {id: 1, path: "test.txt", content: "test", clean: false}
          {id: 2, path: "hell.txt", content: "new test", clean: false}
        ]})
      ]
      Em.run ->
        controller.initialize()
        server.respond()
      expect(controller.get('content.0.active')).to.be.true

  describe '#reset', ->
    it 'resets list of opened documents', ->
      controller.set 'content', [new AIO.Document()]
      Em.run -> controller.reset()
      console.log "content", controller.get("content")
      expect(controller.get("content")).to.be.null

  describe '#resourceType', ->
    it 'is AIO.Document', ->
      expect(controller.get("resourceType")).to.equal AIO.Document

  describe '#resourceUrl', ->
    it 'is resources path of document for the current box', ->
      box = new AIO.Box()
      box.set "id", 123
      Em.run -> AIO.set("router.ideController.content", box)
      expect(controller._resourceUrl()).to.eq "/boxes/123/documents"

  describe '#jsonRoot', ->
    it 'is documents', ->
      expect(controller.get('jsonRoot')).to.equal 'documents'

  describe '#createTab', ->
    tab = null
    beforeEach ->
      tab = new AIO.Document()
      sandbox.spy tab, "sync"
      sandbox.stub(AIO.Document, "create").returns tab

    it 'syncs the newly created document to server', ->
      Em.run -> controller.createTab path: "test.txt", content: "hello"
      expect(tab.sync).to.have.been.called

    it 'do something when sync success', ->

    it 'do something when sync fails', ->

  describe '#removeTab', ->
    tab = null
    beforeEach ->
      tab = new AIO.Document()
      sandbox.spy tab, "destroy"
      Em.run -> controller.set "content", [tab]

    it 'destroys the tab', ->
      Em.run -> controller.removeTab tab
      expect(tab.destroy).to.have.been.called

    it 'do something when destroy success', ->

    it 'do something when destroy fails', ->

