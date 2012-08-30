describe 'AIO.DocumentViewModel', ->
  file = fileVM = doc = vm = null

  beforeEach ->
    file = new AIO.File
    fileVM = new AIO.FileViewModel(file)
    doc = new AIO.Document
    vm = new AIO.DocumentViewModel(doc, fileVM)

  afterEach ->
    kb.utils.release(vm)
    kb.utils.release(fileVM)

  describe '#fileType', ->
    m =
      'LICENSE'               : 'text/plain'
      '.rb'                   : 'text/plain'
      # ruby
      'foo.rb'                : 'text/x-ruby'
      'bar.rbw'               : 'text/x-ruby'
      'hello/world.gemspec'   : 'text/x-ruby'
      'foo.builder'           : 'text/x-ruby'
      'foo.rxml'              : 'text/x-ruby'
      'foo.rjs'               : 'text/x-ruby'
      'foo.rake'              : 'text/x-ruby'
      'rakefile'              : 'text/x-ruby'
      'Rakefile'              : 'text/x-ruby'
      'foo.rant'              : 'text/x-ruby'
      'rantfile'              : 'text/x-ruby'
      'Rantfile'              : 'text/x-ruby'
      '.irbrc'                : 'text/x-ruby'
      'irbrc'                 : 'text/x-ruby'
      '.pryrc'                : 'text/x-ruby'
      'pryrc'                 : 'text/x-ruby'
      'config.ru'             : 'text/x-ruby'
      'Capfile'               : 'text/x-ruby'
      'Gemfile'               : 'text/x-ruby'
      'Guardfile'             : 'text/x-ruby'
      '.Guardfile'            : 'text/x-ruby'
      'vagrantfile'           : 'text/x-ruby'
      'Vagrantfile'           : 'text/x-ruby'
      '.autotest'             : 'text/x-ruby'
      'thorfile'              : 'text/x-ruby'
      'Thorfile'              : 'text/x-ruby'
      'foo.thor'              : 'text/x-ruby'
      'foo.rabl'              : 'text/x-ruby'
      'foo.jbuilder'          : 'text/x-ruby'
      'podfile'               : 'text/x-ruby'
      'Podfile'               : 'text/x-ruby'
      # html
      'foo.html'              : 'text/html'
      # erb
      'foo.erb'               : 'text/x-html-erb'
      'foo.html.erb'          : 'text/x-html-erb'
      'foo.rhtml'             : 'text/x-html-erb'
      # css
      'foo.css'               : 'text/css'
      # js
      'foo.js'                : 'text/javascript'
      'foo.json'              : 'application/json'
      # ejs
      'foo.ejs'               : 'application/x-ejs'
      # coffeescript
      'foo.coffee'            : 'text/x-coffeescript'
      # less
      'foo.less'              : 'text/x-less'
      # markdown
      'foo.markdown'          : 'text/x-markdown'
      'readme.md'             : 'text/x-markdown'
      # c
      'foo.c'                 : 'text/x-csrc'
      'foo.h'                 : 'text/x-csrc'
      # c++
      'foo.cpp'               : 'text/x-c++src'
      'foo.hpp'               : 'text/x-c++src'
      # diff
      'foo.diff'              : 'text/x-diff'
      # lua
      'foo.lua'               : 'text/x-lua'
      # sql
      'foo.sql'               : 'text/x-mysql'
      'foo.mysql'             : 'text/x-mysql'
      # perl
      'foo.pl'                : 'text/x-perl'
      # php
      'foo.php'               : 'application/x-httpd-php'
      # python
      'foo.py'                : 'text/x-python'
      # scheme
      'foo.scm'               : 'text/x-scheme'
      # shellscript
      'foo.sh'                : 'text/x-sh'
      'configure'             : 'text/x-sh'
      # xml
      'foo.xml'               : 'application/xml'
      # yaml
      'foo.yml'               : 'text/x-yaml'
      'foo.yaml'              : 'text/x-yaml'

    _.each m, (fileType, fileName) ->
      it "detects #{fileName} as #{fileType}", ->
        file.set(path: fileName)
        expect(vm.fileType()).toEqual(fileType)

