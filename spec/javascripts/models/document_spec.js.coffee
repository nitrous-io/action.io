describe 'AIO.Document', ->
  model = null

  beforeEach ->
    model = AIO.Document.create content: 'hello'

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

    it "returns false when a document's content has changed", ->
      model.set 'content', 'hello '
      expect(model.get 'clean').to.be.false

    it "returns true when an unsaved document's lastSavedContent has been updated", ->
      model.set 'content', 'hello '
      expect(model.get 'clean').to.be.false
      model.set 'lastSavedContent', 'hello '
      expect(model.get 'clean').to.be.true

  describe 'tooltip', ->
    it 'returns the absolutePath if it exists', ->
      pathObj = {absolutePath: 'foo', name: 'hello'}
      model.set 'path', pathObj
      expect(model.get 'tooltip').to.eql(pathObj.absolutePath)

    it 'returns title if it does not exist', ->
      pathObj = {absolutePath: null, name: 'hello'}
      expect(model.get 'tooltip').to.eql(model.get('title'))
