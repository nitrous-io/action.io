describe 'App.Path', ->
  klass = App.Path
  path = null

  beforeEach ->
    path = klass.create()

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
      path = klass.create()

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
        foo = klass.create absolutePath: 'foo', directory: true, content: [
          bar = klass.create absolutePath: 'foo/bar', directory: true, content: [
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
      path.set 'content', [
        foo = klass.create absolutePath: 'path/to/foo', size: 4096, directory: true
        bar = klass.create absolutePath: 'path/to/bar', size: 4096, directory: true, content: [
          klass.create absolutePath: 'path/to/bar/quux', size: 111
        ]
        baz = klass.create absolutePath: 'path/to/baz', size: 222
        qux = klass.create absolutePath: 'path/to/qux', size: 333
        newPath = klass.create absolutePath: '', new: true
      ]

      fooz = klass.create absolutePath: 'path/to/fooz', size: 444
      App.set 'router.ideSidebarController.content', [foo, bar, baz, qux, fooz]

    afterEach ->
      App.set 'router.ideSidebarController.content', null

    context 'when absolute path is not changed', ->
      beforeEach ->
        path.set 'absolutePath', 'path/to'
        path.updateContent [
          ['foo', true, 4096]
          ['bar', false, 123]
          ['qux', false, 456]
          ['fooz', false, 789]
          ['barz', true, 4096]
        ]
        content = path.get 'content'

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
        fooz = content.findProperty 'absolutePath', 'path/to/fooz'
        barz = content.findProperty 'absolutePath', 'path/to/barz'
        expect(fooz).to.exist
        expect(fooz.get 'directory').to.be.false
        expect(fooz.get 'size').to.equal 789
        expect(barz).to.exist
        expect(barz.get 'directory').to.be.true
        expect(barz.get 'size').to.equal 4096
        expect(content).to.have.length 6

      it 'uses an existing path object in IdeSidebarController.content instead of creating a new path object if possible', ->
        expect(content.findProperty 'absolutePath', 'path/to/bar').to.equal bar
        expect(content.findProperty 'absolutePath', 'path/to/fooz').to.equal fooz

      it 'also removes deleted items from IdeSidebarController.content', ->
        expect(App.get 'router.ideSidebarController.content').to.contain foo
        expect(App.get 'router.ideSidebarController.content').not.to.contain baz
        expect(App.get 'router.ideSidebarController.content').to.contain qux
        expect(App.get 'router.ideSidebarController.content').to.contain fooz

    context 'when the absolute path has changed', ->
      beforeEach ->
        path.set 'absolutePath', 'path/to-new'
        path.updateContent [
          ['foo', true, 4096]
          ['bar', false, 123]
          ['qux', false, 456]
          ['fooz', false, 789]
          ['barz', true, 4096]
        ]
        content = path.get 'content'

      it 'deletes all existing items', ->
        expect(content).not.to.contain foo
        expect(content).not.to.contain bar
        expect(content).not.to.contain baz
        expect(content).not.to.contain qux

      it 'leaves new items', ->
        expect(content).to.contain newPath

      it 'adds all existing items again with new items', ->
        foo = content.findProperty 'absolutePath', 'path/to-new/foo'
        bar = content.findProperty 'absolutePath', 'path/to-new/bar'
        qux = content.findProperty 'absolutePath', 'path/to-new/qux'
        fooz = content.findProperty 'absolutePath', 'path/to-new/fooz'
        barz = content.findProperty 'absolutePath', 'path/to-new/barz'

        expect(foo).to.exist
        expect(foo.get 'directory').to.be.true
        expect(foo.get 'size').to.equal 4096
        expect(bar).to.exist
        expect(bar.get 'directory').to.be.false
        expect(bar.get 'size').to.equal 123
        expect(bar.get('content').length).to.equal 0
        expect(qux).to.exist
        expect(qux.get 'directory').to.be.false
        expect(qux.get 'size').to.equal 456
        expect(fooz).to.exist
        expect(fooz.get 'directory').to.be.false
        expect(fooz.get 'size').to.equal 789
        expect(barz).to.exist
        expect(barz.get 'directory').to.be.true
        expect(barz.get 'size').to.equal 4096
        expect(content).to.have.length 6
