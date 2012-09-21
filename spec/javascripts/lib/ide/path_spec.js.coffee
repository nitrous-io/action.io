#= require spec_helper

describe 'AIO.Path', ->
  klass = AIO.Path
  path = null

  beforeEach ->
    path = klass.create()

  describe '.pathToComponents', ->
    it 'splits path string into path components', ->
      expect(klass.pathToComponents 'foo').to.deep.equal ['foo']
      expect(klass.pathToComponents 'foo/').to.deep.equal ['foo']
      expect(klass.pathToComponents 'foo/bar').to.deep.equal ['foo', 'bar']
      expect(klass.pathToComponents 'foo/bar/').to.deep.equal ['foo', 'bar']
      expect(klass.pathToComponents 'foo/bar/baz').to.deep.equal ['foo', 'bar', 'baz']
      expect(klass.pathToComponents 'foo/bar/baz/').to.deep.equal ['foo', 'bar', 'baz']

  describe '#directory', ->
    context 'when absolutePath is empty', ->
      it 'returns true', ->
        path.set 'absolutePath', ''
        expect(path.get 'directory').to.be.true

    context 'when absolutePath points to a directory', ->
      it 'returns true', ->
        path.set 'absolutePath', 'foo/'
        expect(path.get 'directory').to.be.true
        path.set 'absolutePath', 'foo/bar/'
        expect(path.get 'directory').to.be.true
        path.set 'absolutePath', 'foo/bar/baz/'
        expect(path.get 'directory').to.be.true

    context 'when absolutePath points to a file', ->
      it 'returns false', ->
        path.set 'absolutePath', 'foo'
        expect(path.get 'directory').to.be.false
        path.set 'absolutePath', 'foo/bar'
        expect(path.get 'directory').to.be.false
        path.set 'absolutePath', 'foo/bar/baz'
        expect(path.get 'directory').to.be.false

  describe '#name', ->
    context 'when absolutePath is empty', ->
      it 'returns ~', ->
        path.set 'absolutePath', ''
        expect(path.get 'name').to.equal '~'

    context 'when absolutePath is not empty', ->
      it 'returns the name', ->
        path.set 'absolutePath', 'foo/'
        expect(path.get 'name').to.equal 'foo'
        path.set 'absolutePath', 'foo/bar/'
        expect(path.get 'name').to.equal 'bar'
        path.set 'absolutePath', 'foo/bar/baz/'
        expect(path.get 'name').to.equal 'baz'
        path.set 'absolutePath', 'foo'
        expect(path.get 'name').to.equal 'foo'
        path.set 'absolutePath', 'foo/bar'
        expect(path.get 'name').to.equal 'bar'
        path.set 'absolutePath', 'foo/bar/baz'
        expect(path.get 'name').to.equal 'baz'

  describe '#displayName', ->
    context 'when absolutePath is empty', ->
      it 'returns ~/', ->
        path.set 'absolutePath', ''
        expect(path.get 'displayName').to.equal '~/'

    context 'when absolutePath points to a directory', ->
      it 'returns the name of the directory suffixed with /', ->
        path.set 'absolutePath', 'foo/'
        expect(path.get 'displayName').to.equal 'foo/'
        path.set 'absolutePath', 'foo/bar/'
        expect(path.get 'displayName').to.equal 'bar/'
        path.set 'absolutePath', 'foo/bar/baz/'
        expect(path.get 'displayName').to.equal 'baz/'

    context 'when absolutePath points to a file', ->
      it 'returns the name of the file', ->
        path.set 'absolutePath', 'foo'
        expect(path.get 'displayName').to.equal 'foo'
        path.set 'absolutePath', 'foo/bar'
        expect(path.get 'displayName').to.equal 'bar'
        path.set 'absolutePath', 'foo/bar/baz'
        expect(path.get 'displayName').to.equal 'baz'

  describe '#findByRelativePath', ->
    foo = bar = baz = qux = quux = null

    beforeEach ->
      path.set 'content', [
        foo = klass.create absolutePath: 'foo/', content: [
          bar = klass.create absolutePath: 'foo/bar/', content: [
            baz = klass.create absolutePath: 'foo/bar/baz'
          ]
          qux = klass.create absolutePath: 'foo/qux'
        ]
        quux = klass.create absolutePath: 'quxx'
      ]

    context 'when given empty string', ->
      it 'returns itself', ->
        expect(path.findByRelativePath '').to.equal path

    context 'when given "/"', ->
      it 'returns itself', ->
        expect(path.findByRelativePath '/').to.equal path

    context 'when the path is its direct child', ->
      it 'finds and returns the path', ->
        expect(path.findByRelativePath 'foo/').to.equal foo
        expect(path.findByRelativePath 'quxx').to.equal quux

    context 'when the path is nested', ->
      it 'finds and returns the path', ->
        expect(path.findByRelativePath 'foo/bar/').to.equal bar
        expect(path.findByRelativePath 'foo/qux').to.equal qux
        expect(path.findByRelativePath 'foo/bar/baz').to.equal baz
        expect(foo.findByRelativePath 'bar/').to.equal bar
        expect(foo.findByRelativePath 'qux').to.equal qux

    context 'when the path does not exist', ->
      it 'returns undefined', ->
        expect(path.findByRelativePath 'foo/bleh').to.be.undefined

  describe '#updateContent', ->
    foo = bar = baz = qux = fooz = content = null

    beforeEach ->
      path.set 'content', [
        foo = klass.create absolutePath: 'foo/'
        bar = klass.create absolutePath: 'bar/', content: [
          klass.create absolutePath: 'bar/quux'
        ]
        baz = klass.create absolutePath: 'baz'
        qux = klass.create absolutePath: 'qux'
      ]

      fooz = klass.create absolutePath: 'fooz'
      AIO.set 'router.ideSidebarController.content', [foo, bar, baz, qux, fooz]

      path.updateContent ['foo/', 'bar', 'qux', 'fooz', 'barz/']
      content = path.get 'content'

    afterEach ->
      AIO.set 'router.ideSidebarController.content', null

    it 'keeps items that are unchanged', ->
      expect(content).to.contain foo
      expect(content).to.contain qux

    it 'deletes items that are absent', ->
      expect(content).not.to.contain bar
      expect(content).not.to.contain baz

    it 'adds new items', ->
      expect(content.findProperty 'absolutePath', 'fooz').to.exist
      expect(content.findProperty 'absolutePath', 'barz/').to.exist
      expect(content.findProperty 'absolutePath', 'bar').to.exist
      expect(content).to.have.length 5

    it 'uses an existing path object in IdeSidebarController.content instead of creating a new path object if possible', ->
      expect(content.findProperty 'absolutePath', 'fooz').to.equal fooz

    it 'also removes deleted items from IdeSidebarController.content', ->
      expect(AIO.get 'router.ideSidebarController.content').to.contain foo
      expect(AIO.get 'router.ideSidebarController.content').not.to.contain bar
      expect(AIO.get 'router.ideSidebarController.content').not.to.contain baz
      expect(AIO.get 'router.ideSidebarController.content').to.contain qux
      expect(AIO.get 'router.ideSidebarController.content').to.contain fooz

