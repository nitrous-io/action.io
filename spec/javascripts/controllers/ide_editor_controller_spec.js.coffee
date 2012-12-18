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

    it 'preloaded list of opened documents', ->
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
      expect(controller.get('content')).to.be.empty
      expect(controller.get("preloadedContent.0.id")).to.eql 1
      expect(controller.get("preloadedContent.0.pathname")).to.eql "test.txt"
      expect(controller.get("preloadedContent.1.id")).to.eql 2
      expect(controller.get("preloadedContent.1.pathname")).to.eql "hell.txt"

  describe 'contentDidLoaded', ->
    preloadedContent = null

    beforeEach ->
      preloadedContent = [
        AIO.Document.create().deserialize(id: 1, pathname: "test.txt"),
      ]
      controller.set "preloadedContent", preloadedContent
      controller.set "sftpSocket", sandbox.stub()
      controller.set "sftpSocketReady", true

    it 'inserts preloaded content when the content is loaded', ->
      expect(controller.get("content")).to.be.empty
      Em.run -> preloadedContent[0].set("loaded", true)
      expect(controller.get("content.length")).to.eql 1
      expect(controller.get("content.0.id")).to.eql 1
      expect(controller.get("content.0.pathname")).to.eql "test.txt"

    it 'makes the first tab active', ->
      Em.run -> preloadedContent[0].set("loaded", true)
      expect(controller.get("content.0.active")).to.be.true

    it 'empties the preloaded content', ->
      Em.run -> preloadedContent[0].set("loaded", true)
      expect(controller.get("preloadedContent")).to.be.empty

  describe '#reset', ->
    it 'resets list of opened documents', ->
      controller.set 'content', [new AIO.Document()]
      Em.run -> controller.reset()
      expect(controller.get("content")).to.be.null

    it 'resets list of preloaded documents', ->
      controller.set 'preloadedContent', [new AIO.Document()]
      Em.run -> controller.reset()
      expect(controller.get("preloadedContent")).to.be.null

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

  describe '#saveDocument', ->
    tab = null
    beforeEach ->
      tab = new AIO.Document()
      sandbox.stub tab, "saveContent"
      Em.run -> controller.set "content", [tab]

    it 'saves the document', ->
      tab.set "pathname", "hello/world.txt"
      Em.run -> controller.saveDocument tab
      expect(tab.saveContent).to.have.been.called

    it 'triggers save dialog when the document does not contain a path', ->
      Em.run -> controller.saveDocument tab
      expect(tab.saveContent).not.to.have.been.called
      expect(controller.get("saveDialog.document")).to.equal tab
