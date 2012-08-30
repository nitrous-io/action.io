describe 'aio.models.File', ->
  file = null

  context 'when it is a file', ->
    before ->
      file = new aio.models.File(name: 'foo', path: 'bar/foo')

    it 'sets the attributes', ->
      expect(file.get('name')).toEqual 'foo'
      expect(file.get('path')).toEqual 'bar/foo'

    it 'is not a directory', ->
      expect(file.get('directory')).toBe false

  context 'when it is a directory', ->
    before ->
      file = new aio.models.File(name: 'my_app', path: 'my_app/')

    it 'is a directory', ->
      expect(file.get('directory')).toBe true

    it 'sets the attributes', ->
      expect(file.get('name')).toEqual 'my_app'
      expect(file.get('path')).toEqual 'my_app/'

  describe '#parseList', ->
    doAction = ->
      file.parseList(['README', 'config/', 'boo', 'app/'])

    context 'when it is a file', ->
      before ->
        file = new aio.models.File(name: 'foo', path: 'bar/foo')
        doAction()

      it 'does nothing', ->
        expect(file.get('children')).toEqual null

    context 'when it is a directory', ->
      before ->
        file = new aio.models.File(name: 'my_app', path: 'my_app/')
        doAction()

      it 'parses given files array and creates a sorted collection', ->
        expect(file.get('children').length).toEqual 4
        expect(file.get('children').at(0).get('name')).toEqual 'app'
        expect(file.get('children').at(0).get('path')).toEqual 'my_app/app/'
        expect(file.get('children').at(0).get('directory')).toBe true
        expect(file.get('children').at(1).get('name')).toEqual 'boo'
        expect(file.get('children').at(1).get('path')).toEqual 'my_app/boo'
        expect(file.get('children').at(1).get('directory')).toBe false
        expect(file.get('children').at(2).get('name')).toEqual 'config'
        expect(file.get('children').at(2).get('path')).toEqual 'my_app/config/'
        expect(file.get('children').at(2).get('directory')).toBe true
        expect(file.get('children').at(3).get('name')).toEqual 'README'
        expect(file.get('children').at(3).get('path')).toEqual 'my_app/README'
        expect(file.get('children').at(3).get('directory')).toBe false

  describe '#findFile', ->
    haha = baz = rofl = null

    before ->
      file = new aio.models.File(name: '~', path: '/')
      file.parseList(['foo/', 'lol'])
      foo = file.get('children').where(name: 'foo')[0]
      foo.parseList(['haha', 'bar/'])
      haha = foo.get('children').where(name: 'haha')[0]
      bar = foo.get('children').where(name: 'bar')[0]
      bar.parseList(['lulz', 'baz', 'rofl/'])
      baz = bar.get('children').where(name: 'baz')[0]
      rofl = bar.get('children').where(name: 'rofl')[0]

    it 'finds a file object by path', ->
      expect(file.findFile('/')).toBe file
      expect(file.findFile('/foo/haha')).toBe haha
      expect(file.findFile('/foo/bar/baz')).toBe baz
      expect(file.findFile('/foo/bar/rofl/')).toEqual rofl
      expect(file.findFile('/foo/baz')).toEqual null
      expect(file.findFile('/foo/baz/lol')).toEqual null

