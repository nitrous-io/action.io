describe 'AIO.Path', ->
  klass = AIO.Path
  controller = null
  path = null

  beforeEach ->
    Em.run -> controller = AIO.lookup 'controller:ideSidebar'
    path = klass.create controller

  describe 'beingDeleted', ->
    it 'is false by default', ->
      expect(path.get 'beingDeleted').to.be.false

  describe '.pathToComponents', ->
    it 'splits path string into path components', ->
      expect(klass.pathToComponents 'foo').to.deep.equal ['foo']
      expect(klass.pathToComponents 'foo/bar').to.deep.equal ['foo', 'bar']
      expect(klass.pathToComponents 'foo/bar/baz').to.deep.equal ['foo', 'bar', 'baz']

  describe '#name', ->
    context 'when absolutePath is empty', ->
      it 'returns ~', ->
        path.set 'absolutePath', ''
        expect(path.get 'name').to.equal '~'

    context 'when absolutePath is not empty', ->
      it 'returns the name', ->
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
        path.set 'directory', true
        expect(path.get 'displayName').to.equal '~/'

    context 'when absolutePath points to a directory', ->
      it 'returns the name of the directory suffixed with /', ->
        path.set 'absolutePath', 'foo'
        path.set 'directory', true
        expect(path.get 'displayName').to.equal 'foo/'
        path.set 'absolutePath', 'foo/bar'
        path.set 'directory', true
        expect(path.get 'displayName').to.equal 'bar/'
        path.set 'absolutePath', 'foo/bar/baz'
        path.set 'directory', true
        expect(path.get 'displayName').to.equal 'baz/'

    context 'when absolutePath points to a file', ->
      it 'returns the name of the file', ->
        path.set 'absolutePath', 'foo'
        expect(path.get 'displayName').to.equal 'foo'
        path.set 'absolutePath', 'foo/bar'
        expect(path.get 'displayName').to.equal 'bar'
        path.set 'absolutePath', 'foo/bar/baz'
        expect(path.get 'displayName').to.equal 'baz'

  describe '#hidden', ->
    context 'when the name begins with a period(.)', ->
      it 'returns true', ->
        path.set 'absolutePath', 'some/path/.foo'
        expect(path.get 'hidden').to.be.true

    context 'when the name does not begin with a period(.)', ->
      it 'returns false', ->
        path.set 'absolutePath', 'some/path/foo'
        expect(path.get 'hidden').to.be.false

  describe '#parentAbsolutePath', ->
    beforeEach ->
      path = klass.create controller

    it 'returns the absolutePath of the parent path', ->
      path.set 'absolutePath', ''
      expect(path.get 'parentAbsolutePath').not.to.exist
      path.set 'absolutePath', 'foo'
      expect(path.get 'parentAbsolutePath').to.equal ''
      path.set 'absolutePath', 'foo/bar'
      expect(path.get 'parentAbsolutePath').to.equal 'foo'
      path.set 'absolutePath', 'foo/bar/baz'
      expect(path.get 'parentAbsolutePath').to.equal 'foo/bar'

  describe '#findByRelativePath', ->
    foo = bar = baz = qux = quux = null

    beforeEach ->
      path.set 'content', [
        foo = klass.create controller, absolutePath: 'foo', directory: true, content: [
          bar = klass.create controller, absolutePath: 'foo/bar', directory: true, content: [
            baz = klass.create controller, absolutePath: 'foo/bar/baz'
          ]
          qux = klass.create controller, absolutePath: 'foo/qux'
        ]
        quux = klass.create controller, absolutePath: 'quxx'
      ]

    context 'when given empty string', ->
      it 'returns itself', ->
        expect(path.findByRelativePath '').to.equal path

    context 'when given "/"', ->
      it 'returns itself', ->
        expect(path.findByRelativePath '/').to.equal path

    context 'when the path is its direct child', ->
      it 'finds and returns the path', ->
        expect(path.findByRelativePath 'foo').to.equal foo
        expect(path.findByRelativePath 'quxx').to.equal quux

    context 'when the path is nested', ->
      it 'finds and returns the path', ->
        expect(path.findByRelativePath 'foo/bar').to.equal bar
        expect(path.findByRelativePath 'foo/qux').to.equal qux
        expect(path.findByRelativePath 'foo/bar/baz').to.equal baz
        expect(foo.findByRelativePath 'bar').to.equal bar
        expect(foo.findByRelativePath 'qux').to.equal qux

    context 'when the path does not exist', ->
      it 'returns undefined', ->
        expect(path.findByRelativePath 'foo/bleh').to.be.undefined

  describe '#updateContent', ->
    foo = bar = baz = qux = fooz = newPath = content = null

    beforeEach ->
      Em.run ->
        path.set 'content', [
          foo = klass.create controller, absolutePath: 'foo', size: 4096, directory: true
          bar = klass.create controller, absolutePath: 'bar', size: 4096, directory: true, content: [
            klass.create controller, absolutePath: 'bar/quux', size: 111
          ]
          baz = klass.create controller, absolutePath: 'baz', size: 222
          qux = klass.create controller, absolutePath: 'qux', size: 333
          newPath = klass.create controller, absolutePath: '', new: true
        ]

        fooz = klass.create controller, absolutePath: 'fooz', size: 444
        controller.set 'content', [foo, bar, baz, qux, fooz]

        path.updateContent controller, [
          ['foo', true, 4096]
          ['bar', false, 123]
          ['qux', false, 456]
          ['fooz', false, 789]
          ['barz', true, 4096]
        ]
        content = path.get 'content'

    afterEach ->
      Em.run -> controller.set 'content', null

    it 'updates existing items', ->
      expect(content).to.contain foo
      expect(foo.get 'directory').to.be.true
      expect(foo.get 'size').to.equal 4096
      expect(content).to.contain.bar
      expect(bar.get 'directory').to.be.false
      expect(bar.get 'size').to.equal 123
      expect(bar.get('content').length).to.equal 0
      expect(content).to.contain qux
      expect(qux.get 'directory').to.be.false
      expect(qux.get 'size').to.equal 456

    it 'deletes items that are absent', ->
      expect(content).not.to.contain baz

    it 'leaves new items', ->
      expect(content).to.contain newPath

    it 'adds new items', ->
      fooz = content.findProperty 'absolutePath', 'fooz'
      barz = content.findProperty 'absolutePath', 'barz'
      expect(fooz).to.exist
      expect(fooz.get 'directory').to.be.false
      expect(fooz.get 'size').to.equal 789
      expect(barz).to.exist
      expect(barz.get 'directory').to.be.true
      expect(barz.get 'size').to.equal 4096
      expect(content).to.have.length 6

    it 'uses an existing path object in IdeSidebarController.content instead of creating a new path object if possible', ->
      expect(content.findProperty 'absolutePath', 'bar').to.equal bar
      expect(content.findProperty 'absolutePath', 'fooz').to.equal fooz

    it 'also removes deleted items from IdeSidebarController.content', ->
      expect(controller.get 'content').to.contain foo
      expect(controller.get 'content').not.to.contain baz
      expect(controller.get 'content').to.contain qux
      expect(controller.get 'content').to.contain fooz

