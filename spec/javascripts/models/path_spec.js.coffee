describe 'AIO.Path', ->
  path = null

  beforeEach ->
    path = AIO.Path.create()

  describe '#directory', ->
    context 'when absolutePath is empty', ->
      it 'returns true', ->
        path.set 'absolutePath', ''
        expect(path.get('directory')).to.be.true

    context 'when absolutePath points to a directory', ->
      it 'returns true', ->
        path.set 'absolutePath', 'foo/'
        expect(path.get('directory')).to.be.true
        path.set 'absolutePath', 'foo/bar/'
        expect(path.get('directory')).to.be.true
        path.set 'absolutePath', 'foo/bar/baz/'
        expect(path.get('directory')).to.be.true

    context 'when absolutePath points to a file', ->
      it 'returns false', ->
        path.set 'absolutePath', 'foo'
        expect(path.get('directory')).to.be.false
        path.set 'absolutePath', 'foo/bar'
        expect(path.get('directory')).to.be.false
        path.set 'absolutePath', 'foo/bar/baz'
        expect(path.get('directory')).to.be.false

  describe '#name', ->
    context 'when absolutePath is empty', ->
      it 'returns ~/', ->
        path.set 'absolutePath', ''
        expect(path.get('name')).to.equal '~/'

    context 'when absolutePath points to a directory', ->
      it 'returns the name of the directory suffixed with /', ->
        path.set 'absolutePath', 'foo/'
        expect(path.get('name')).to.equal 'foo/'
        path.set 'absolutePath', 'foo/bar/'
        expect(path.get('name')).to.equal 'bar/'
        path.set 'absolutePath', 'foo/bar/baz/'
        expect(path.get('name')).to.equal 'baz/'

    context 'when absolutePath points to a file', ->
      it 'returns the name of the file', ->
        path.set 'absolutePath', 'foo'
        expect(path.get('name')).to.equal 'foo'
        path.set 'absolutePath', 'foo/bar'
        expect(path.get('name')).to.equal 'bar'
        path.set 'absolutePath', 'foo/bar/baz'
        expect(path.get('name')).to.equal 'baz'

