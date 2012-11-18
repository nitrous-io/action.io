#= require spec_helper

describe 'AIO.SaveDialog', ->
  model = null

  beforeEach ->
    model = AIO.SaveDialog.create()

  describe 'validations', ->
    context 'path', ->
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
#        '"my_app.rb"' : false
        'my:app.rb'   : false

      it "validates and determines correct path", ->
        _.each f, (valid, path) ->
          model.set 'path', path
          model.validate()
          if valid
            expect(model.get 'errors.path').not.to.exist
          else
            expect(model.get 'errors.path').to.exist
