describe 'AIO.SaveDialogViewModel', ->
  vm = null

  beforeEach ->
    vm = new AIO.SaveDialogViewModel

  describe '#validatePath', ->
    f =
      'README'      : true
      '.Gemfile'    : true
      '.hello.'     : true
      '.'           : false
      '..'          : false
      '...'         : false
      '...foo'      : true
      'foo'         : true
      'foo.'        : true
      'foo..'       : true
      'foo/'        : false
      'foo/bar'     : true
      'foo/bar/'    : false
      'foo/.'       : false
      'foo/..'      : false
      'foo/./'      : false
      'foo//bar'    : false
      'foo/./bar'   : false
      'foo/../bar'  : false
      'foo/bar/baz' : true
      'my_app.rb'   : true
      'my app.rb'   : true
      'my\\app.rb'  : false
      'my*app.rb'   : false
      'my?app.rb'   : false
      '<my app>'    : false
      'my|app.rb'   : false
      '"my_app.rb"' : false
      'my:app.rb'   : false
    _.each f, (valid, path) ->
      it "validates and determines #{path} to be #{if valid then 'valid' else 'invalid'}", ->
        vm.path(path)
        expect(vm.validatePath()).toBe(valid)

