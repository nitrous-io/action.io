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

  describe 'tooltip', ->
    it 'returns the absolutePath if it exists', ->
      pathObj = {absolutePath: 'foo', name: 'hello'}
      model.set 'path', pathObj
      expect(model.get 'tooltip').to.eql(pathObj.absolutePath)

    it 'returns title if it does not exist', ->
      pathObj = {absolutePath: null, name: 'hello'}
      expect(model.get 'tooltip').to.eql(model.get('title'))
