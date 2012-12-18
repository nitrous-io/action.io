describe 'AIO.Document', ->
  fs = null
  model = null

  beforeEach ->
    fs = {
      writeFile: ->
      fetchFileContent: ->
    }
    model = AIO.Document.create content: 'hello'

  describe '#title', ->
    it 'returns the file name if it exists', ->
      model.set 'pathname', 'hello/world.txt'
      expect(model.get 'title').to.eql('world.txt')

    it 'returns untitled if it does not exist', ->
      model.set 'pathname', null
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

  describe '#focusDidChange', ->
    document = null

    beforeEach ->
      sandbox.spy AIO.Document.prototype, "saveContent"
      document = AIO.Document.create()

    it 'saves the document when the document loses focus', ->
      expect(AIO.Document.prototype.saveContent).not.to.have.been.called
      document.set "focused", true
      expect(AIO.Document.prototype.saveContent).not.to.have.been.called
      document.set "focused", false
      expect(AIO.Document.prototype.saveContent).to.have.been.called

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
      doc = AIO.Document.create pathname: "test.txt", content: "test", dirty: false

    it 'does not sync when the document is a new file', ->
      document = AIO.Document.create()
      sandbox.spy document, "saveResource"
      document.sync()
      expect(document.saveResource).not.to.have.been.called

    it 'saves the document to server', (done) ->
      server.respondWith 'POST', '/boxes/123/documents', [
        200
        { 'Content-Type': 'application/json; charset=utf-8' }
        JSON.stringify({document: {id: 1, pathname: "test.txt"}})
      ]
      Em.run ->
        doc.sync (err, doc) ->
          expect(err).to.be.nil
          expect(doc.get("id")).to.equal 1
          expect(doc.get("pathname")).to.equal "test.txt"
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
      doc = AIO.Document.create pathname: "test.txt"
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
    path = null

    beforeEach ->
      sandbox.spy fs, "writeFile"
      model.set "content", "test content"
      model.set "fileSystem", fs
      model.set "fileSystemReady", true
      model.set "pathname", "test.txt"
      model.set "loadCount", 0 # reset loadcount before test

    it 'does not do anything when filesystem socket is not ready', ->
      model.set "fileSystemReady", false
      model.saveContent()
      expect(fs.writeFile).not.to.have.been.called

    it 'does not do anything when filesystem socket is not there', ->
      model.set "fileSystem", undefined
      model.saveContent()
      expect(fs.writeFile).not.to.have.been.called

    it 'calls writeFile with correct content', ->
      model.saveContent()
      expect(fs.writeFile).to.have.been.calledWith('test.txt', 'test content', sinon.match.func)

    it 'does not save if the file is being saved', ->
      model.saveContent()
      model.saveContent()
      expect(fs.writeFile).to.have.been.calledOnce

    it 'increments loadCount', ->
      loadCount = model.get("loadCount")
      model.saveContent()
      expect(model.get("loadCount")).to.equal loadCount + 1

    it 'sets lastSavedContent when the save finish', ->
      model.saveContent()
      fs.writeFile.callArgWith 2, null, "test.txt"
      expect(model.get("lastSavedContent")).to.eql 'test content'

    it 'resets loadCount when the save finish', ->
      loadCount = model.get("loadCount")
      model.saveContent()
      fs.writeFile.callArgWith 2, null, "test.txt"
      expect(model.get("loadCount")).to.equal loadCount

  describe '#loadContent', ->
    path = null

    beforeEach ->
      sandbox.spy fs, "fetchFileContent"
      model.set "content", ""
      model.set "fileSystem", fs
      model.set "fileSystemReady", true
      model.set "pathname", "test.txt"

    it 'calls fetchFileContent with correct content', ->
      model.loadContent()
      expect(fs.fetchFileContent).to.have.been.calledWith('test.txt', sinon.match.func)

    it 'sets content after content is loaded', ->
      model.loadContent()
      fs.fetchFileContent.callArgWith 1, null, "test.txt", "new content is here"
      expect(model.get("content")).to.eql 'new content is here'

    it 'increments loadCount', ->
      loadCount = model.get("loadCount")
      model.loadContent()
      expect(model.get("loadCount")).to.equal(loadCount + 1)

    it 'resets loadCount when the load finish', ->
      loadCount = model.get("loadCount")
      model.loadContent()
      fs.fetchFileContent.callArgWith 1, null, "test.txt", "new content is here"
      expect(model.get("loadCount")).to.equal 0

    it 'calls a callback after successfully loading content', ->
      cb = sandbox.stub()
      model.loadContent cb
      fs.fetchFileContent.callArgWith 1, null, "test.txt", "new content is here"
      expect(cb).to.have.been.calledWith model

  describe '#prepareContentWhenReady', ->
    beforeEach ->
      sandbox.stub model, "loadContent"
      Em.run ->
        model.set "pathname", "hello.txt"
        model.set "content", null
        model.set "fileSystem", fs
        model.set "fileSystemReady", false
        model.set "fileSystem", "test.txt"

    it 'loads content when the file system is ready', ->
      expect(model.loadContent).not.to.have.been.called
      Em.run -> model.set "fileSystemReady", true
      expect(model.loadContent).to.have.been.called
