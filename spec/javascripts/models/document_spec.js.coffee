describe 'AIO.Document', ->
  model = null

  beforeEach ->
    model = AIO.Document.create content: 'hello'

  describe '#path', ->
    sidebar = null
    context 'when document with pathname is created without path', ->
      beforeEach ->
        Em.run ->
          sidebar = AIO.get "router.ideSidebarController"
          sidebar.initialize()

      it 'sets to correct path when the path is loaded', ->
        Em.run ->
          model.set "pathname", "test.txt"
          sidebar.content.pushObject new AIO.Path().set("absolutePath", "file.txt")
          sidebar.content.pushObject new AIO.Path().set("absolutePath", "test.txt")
        expect(model.get("path.absolutePath")).to.equal "test.txt"

  describe 'title', ->
    it 'returns the path name if it exists', ->
      pathObj = {name: 'foo'}
      model.set 'path', pathObj
      expect(model.get 'title').to.eql(pathObj.name)

    it 'returns untitled if it does not exist', ->
      model.set 'path', null
      expect(model.get 'title').to.eql("Untitled 1")

    it 'returns untitled 2 if there is a previous untitled document', ->
      newModel = AIO.Document.create()
      expect(newModel.get 'title').to.eql("Untitled 2")

  describe 'clean', ->
    it 'returns true when a document is initially created', ->
      expect(model.get 'clean').to.be.true

    it 'returns false when a document\'s content has changed', ->
      model.set 'content', 'hello '
      expect(model.get 'clean').to.be.false

    it 'returns true when an unsaved document\'s lastSavedContent has been updated', ->
      model.set 'content', 'hello '
      expect(model.get 'clean').to.be.false
      model.set 'lastSavedContent', 'hello '
      expect(model.get 'clean').to.be.true

  describe '#pathname', ->
    it 'returns absolute path', ->
      pathObj = { absolutePath: 'foo'}
      model.set 'path', pathObj
      expect(model.get 'pathname').to.eql(pathObj.absolutePath)

  describe 'closeButtonClass', ->
    it "returns 'icon-remove' when the document is clean", ->
      expect(model.get 'closeButtonClass').to.eql('icon-remove')

    it "returns 'icon-asterisk' when the document is not clean", ->
      model.set 'content', 'hello '
      expect(model.get 'closeButtonClass').to.eql('icon-asterisk')

  describe '#resourceName', ->
    it 'is document resource name', ->
      expect(model.get("resourceName")).to.eq "document"

  describe '#resourceUrl', ->
    it 'belongs to a box', ->
      box = new AIO.Box()
      box.set "id", 123
      Em.run -> AIO.set("router.ideController.content", box)
      expect(model.get("resourceUrl")).to.eq "/boxes/123/documents"

  describe '#_resourceUrl', ->
    it 'belongs to a box', ->
      box = new AIO.Box()
      box.set "id", 123
      Em.run -> AIO.set("router.ideController.content", box)
      expect(model._resourceUrl()).to.eq "/boxes/123/documents"

  describe '#resourceProperties', ->
    it 'returns document properties', ->
      properties = model.get("resourceProperties")
      expect(properties).to.include 'pathname'
      expect(properties).to.include 'content'
      expect(properties).to.include 'clean'

  describe '#sync', ->
    doc = box = null
    beforeEach ->
      box = new AIO.Box()
      box.set "id", 123
      Em.run -> AIO.set("router.ideController.content", box)
      doc = AIO.Document.create path: "test.txt", content: "test", dirty: false

    it 'saves the document to server', (done) ->
      server.respondWith 'POST', '/boxes/123/documents', [
        200
        { 'Content-Type': 'application/json; charset=utf-8' }
        JSON.stringify({document: {id: 1, path: "test.txt", content: "test", dirty: false}})
      ]
      Em.run ->
        doc.sync (err, doc) ->
          expect(err).to.be.nil
          expect(doc.get("id")).to.equal 1
          expect(doc.get("path")).to.equal "test.txt"
          expect(doc.get("content")).to.equal "test"
          done()
        server.respond()

    it 'callbacks with errors when it fails', (done) ->
      Em.run ->
        doc.sync (err, doc) ->
          expect(err).not.to.be.nil
          expect(doc.get("id")).to.be.undefined
          done()
        server.respond()

  describe '#destroy', ->
    doc = box = null
    beforeEach ->
      box = new AIO.Box()
      box.set "id", 123
      Em.run -> AIO.set("router.ideController.content", box)
      doc = AIO.Document.create path: "test.txt", content: "test", dirty: false
      doc.set "id", 234

    it 'destroys the document on server', (done) ->
      server.respondWith 'DELETE', '/boxes/123/documents/234', [
        204
        { 'Content-Type': 'application/json; charset=utf-8' },
        ""
      ]
      Em.run ->
        doc.destroy (err, doc) ->
          expect(err).to.be.nil
          done()
        server.respond()

    it 'callbacks with errors when it fails', (done) ->
      Em.run ->
        doc.destroy (err, doc) ->
          expect(err).not.to.be.nil
          done()
        server.respond()
