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
          {id: 1, pathname: "test.txt"}
          {id: 2, pathname: "hell.txt"}
        ]})
      ]
      Em.run ->
        controller.initialize()
        server.respond()
      expect(controller.get('content.0.active')).to.be.true

    it 'does not do anything when the user does not have any documents', ->
      server.respondWith 'GET', '/boxes/123/documents', [
        200
        { 'Content-Type': 'application/json; charset=utf-8' }
        JSON.stringify({documents: []})
      ]
      Em.run ->
        controller.initialize()
        server.respond()
      expect(controller.get('content')).to.be.empty

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

  describe '#removeTab', ->
    tab = null
    beforeEach ->
      tab = new AIO.Document()
      sandbox.spy tab, "destroy"
      Em.run -> controller.set "content", [tab]

    it 'destroys the tab', ->
      Em.run -> controller.removeTab tab
      expect(tab.destroy).to.have.been.called

  describe '#openDocument', ->
    document = null

    beforeEach ->
      document = new AIO.Document
      sandbox.stub(document, "loadContent")
      sandbox.stub(document, "sync")
      sandbox.stub(AIO.Document, "create").returns document
      sandbox.spy controller, "addTab"

    context "when the document is not being opened", ->
      it 'saves the document into content', ->
        controller.openDocument 'hello/world.txt'
        content = controller.get('content')
        expect(AIO.Document.create).to.have.been.calledWith pathname: 'hello/world.txt'

      it 'loads the content of the document', ->
        controller.openDocument 'hello/world.txt'
        expect(document.loadContent).to.have.been.called

      it 'creates a new tab for the document', ->
        controller.openDocument 'hello/world.txt'
        document.loadContent.callArgWith 0, document
        expect(controller.addTab).to.have.been.calledWith document

      it 'syncs the document to server', ->
        controller.openDocument 'hello/world.txt'
        document.loadContent.callArgWith 0, document
        expect(document.sync).to.have.been.called
    
    context "when the document is being opened", ->
      beforeEach ->
        document = AIO.Document.create()
        document.set 'pathname', 'hello/world.txt'
        Em.run -> controller.get("content").push document

      it 'activates the document', ->
        sandbox.spy controller, "makeTabActive"
        controller.openDocument 'hello/world.txt'
        expect(controller.makeTabActive).to.have.been.calledWith document
