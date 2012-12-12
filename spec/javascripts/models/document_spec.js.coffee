describe 'AIO.Document', ->
  model = null

  beforeEach ->
    model = AIO.Document.create content: 'hello'

  describe '#pathDidFind', ->
    sidebar = null

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

    it 'loads the content of the document', ->
      sandbox.stub model, "loadContent"
      Em.run ->
        model.set "pathname", "test.txt"
        sidebar.content.pushObject new AIO.Path().set("absolutePath", "file.txt")
        sidebar.content.pushObject new AIO.Path().set("absolutePath", "test.txt")
      expect(model.loadContent).to.have.been.called

  describe '#title', ->
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

  describe '#clean', ->
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

  describe '#cleanDidChange', ->
    clock = document = null

    beforeEach ->
      document = AIO.Document.create()
      clock = sandbox.useFakeTimers()
      sandbox.spy document, "saveContent"

    afterEach -> clock.restore()

    it 'saves the document when there are changes to content and lastSavedContent', ->
      document.set 'content', 'hello '
      clock.tick(AIO.Document.SYNC_TIMEOUT + 1)
      expect(document.saveContent).to.have.been.called
      document.set 'lastSavedContent', 'hello '
      clock.tick(AIO.Document.SYNC_TIMEOUT + 1)
      expect(document.saveContent).to.have.been.called

    # doing this meant that we only tries to save the content after the last
    # change
    it 'resets the timeout after every changes', ->
      document.set 'content', 'hello '
      clock.tick(AIO.Document.SYNC_TIMEOUT - 10)
      document.set 'content', 'hello world'
      clock.tick(11)
      expect(document.saveContent).not.to.have.been.called
      clock.tick(AIO.Document.SYNC_TIMEOUT + 1)
      expect(document.saveContent).to.have.been.calledOnce

  describe '#pathname', ->
    it 'returns absolute path', ->
      pathObj = { absolutePath: 'foo'}
      model.set 'path', pathObj
      expect(model.get 'pathname').to.eql(pathObj.absolutePath)

    it 'sets the value when create with path', ->
      model = AIO.Document.create(path: {absolutePath: 'foo'})
      expect(model.get 'pathname').to.eql('foo')

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

  describe '#sync', ->
    doc = box = null
    beforeEach ->
      box = new AIO.Box()
      box.set "id", 123
      Em.run -> AIO.set("router.ideController.content", box)
      doc = AIO.Document.create path: "test.txt", content: "test", dirty: false

    it 'does not sync when the document is a new file', ->
      document = AIO.Document.create()
      sandbox.spy document, "saveResource"
      document.sync()
      expect(document.saveResource).not.to.have.been.called

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

    it 'does not destroy when the document is a new file', ->
      document = AIO.Document.create()
      sandbox.spy document, "destroyResource"
      document.destroy()
      expect(document.destroyResource).not.to.have.been.called

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

  describe '#fileSystem', ->
    it 'bounds to ideController#sftpSocket', ->
      socket = "socket"
      Em.run -> AIO.set('router.ideController.sftpSocket', socket)
      expect(model.get("fileSystem")).to.equal socket

  describe '#fileSystemReady', ->
    it 'bounds to fileSystem#started', ->
      Em.run -> model.set("fileSystem", {started: false})
      expect(model.get("fileSystemReady")).to.be.false

  describe '#saveContent', ->
    fs = path = null
    beforeEach ->
      fs = { writeFile: -> }
      path = AIO.Path.create(absolutePath: "test.txt")
      sandbox.spy fs, "writeFile"
      model.set "content", "test content"
      model.set "fileSystem", fs
      model.set "fileSystemReady", true
      model.set "path", path

    it 'does not do anything when filesystem socket is not ready', ->
      model.set "fileSystemReady", false
      model.saveContent()
      expect(fs.writeFile).not.to.have.been.called

    it 'does not do anything when the path does not exist', ->
      model.set "path", undefined
      model.saveContent()
      expect(fs.writeFile).not.to.have.been.called

    it 'does not do anything when filesystem socket is not there', ->
      model.set "fileSystem", undefined
      model.saveContent()
      expect(fs.writeFile).not.to.have.been.called

    it 'increments loadcount of the path when saving', ->
      loadCount = path.get("loadCount")
      model.saveContent()
      expect(path.get("loadCount")).to.eql loadCount + 1

    it 'calls writeFile with correct content', ->
      model.saveContent()
      expect(fs.writeFile).to.have.been.calledWith('test.txt', 'test content', sinon.match.func)

    it 'decrements loadcount of the path when finishing', ->
      model.saveContent()
      loadCount = path.get("loadCount")
      fs.writeFile.callArgWith 2, null, "test.txt"
      expect(path.get("loadCount")).to.eql loadCount - 1

    it 'sets lastSavedContent when the save finish', ->
      model.saveContent()
      fs.writeFile.callArgWith 2, null, "test.txt"
      expect(model.get("lastSavedContent")).to.eql 'test content'

  describe '#loadContent', ->
    fs = path = null
    beforeEach ->
      fs = { fetchFileContent: -> }
      path = AIO.Path.create(absolutePath: "test.txt")
      sandbox.spy fs, "fetchFileContent"
      model.set "content", ""
      model.set "fileSystem", fs
      model.set "fileSystemReady", true
      model.set "path", path

    it 'increments loadcount of the path when fetching content', ->
      loadCount = path.get("loadCount")
      model.loadContent()
      expect(path.get("loadCount")).to.eql loadCount + 1

    it 'calls fetchFileContent with correct content', ->
      model.loadContent()
      expect(fs.fetchFileContent).to.have.been.calledWith('test.txt', sinon.match.func)

    it 'decrements loadcount of the path when finishing', ->
      model.loadContent()
      loadCount = path.get("loadCount")
      fs.fetchFileContent.callArgWith 1, null, "test.txt", "new content is here"
      expect(path.get("loadCount")).to.eql loadCount - 1

    it 'sets lastSavedContent when the save finish', ->
      model.loadContent()
      fs.fetchFileContent.callArgWith 1, null, "test.txt", "new content is here"
      expect(model.get("content")).to.eql 'new content is here'
