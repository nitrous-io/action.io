#= require codemirror
#= require codemirror/modes/clike
#= require codemirror/modes/clojure
#= require codemirror/modes/coffeescript
#= require codemirror/modes/css
#= require codemirror/modes/diff
#  require codemirror/modes/ecl
#= require codemirror/modes/erlang
#  require codemirror/modes/gfm
#= require codemirror/modes/go
#  require codemirror/modes/groovy
#  require codemirror/modes/haskell
#= require codemirror/modes/htmlembedded
#= require codemirror/modes/htmlmixed
#= require codemirror/modes/javascript
#  require codemirror/modes/jinja2
#= require codemirror/modes/less
#= require codemirror/modes/lua
#= require codemirror/modes/markdown
#= require codemirror/modes/mysql
#  require codemirror/modes/ntriples
#  require codemirror/modes/pascal
#= require codemirror/modes/perl
#= require codemirror/modes/php
#  require codemirror/modes/pig
#  require codemirror/modes/plsql
#  require codemirror/modes/properties
#= require codemirror/modes/python
#  require codemirror/modes/r
#  require codemirror/modes/rpm-changes
#  require codemirror/modes/rpm-spec
#  require codemirror/modes/rst
#= require codemirror/modes/ruby
#  require codemirror/modes/rust
#= require codemirror/modes/scheme
#= require codemirror/modes/shell
#  require codemirror/modes/smalltalk
#  require codemirror/modes/smarty
#  require codemirror/modes/sparql
#  require codemirror/modes/stex
#  require codemirror/modes/tiddlywiki
#  require codemirror/modes/tiki
#  require codemirror/modes/vbscript
#  require codemirror/modes/velocity
#  require codemirror/modes/verilog
#= require codemirror/modes/xml
#  require codemirror/modes/xquery
#= require codemirror/modes/yaml

# ERB
CodeMirror.defineMIME('text/x-html-erb', name: 'htmlembedded', scriptingModeSpec: 'text/x-ruby')

CodeMirror.MODES =
  'text/plain'              : 'Plain Text'
  'text/x-csrc'             : 'C'
  'text/x-c++src'           : 'C++'
  #'text/x-java'
  #'text/x-csharp'
  #'text/x-scala'
  'text/x-clojure'          : 'Clojure'
  'text/css'                : 'CSS'
  'text/x-scss'             : 'SCSS'
  'text/x-coffeescript'     : 'CoffeeScript'
  'text/x-diff'             : 'Diff'
  'text/x-erlang'           : 'Erlang'
  #'application/x-aspx'
  #'application/x-jsp'
  'text/x-go'               : 'Go'
  'text/html'               : 'HTML'
  'text/x-html-erb'         : 'HTML (ERB)'
  'application/x-ejs'       : 'HTML (EJS)'
  'text/x-java'             : 'Java'
  'text/javascript'         : 'JavaScript'
  'application/json'        : 'JSON'
  'application/x-jsp'       : 'JSP'
  'text/x-less'             : 'Less'
  'text/x-lua'              : 'Lua'
  'text/x-markdown'         : 'Markdown'
  'text/x-mysql'            : 'SQL'
  'text/x-perl'             : 'Perl'
  'application/x-httpd-php' : 'PHP'
  #'text/x-php'
  'text/x-python'           : 'Python'
  'text/x-ruby'             : 'Ruby'
  'text/x-scala'            : 'Scala'
  'text/x-scheme'           : 'Scheme'
  'text/x-sh'               : 'Shell Script'
  'application/xml'         : 'XML'
  'text/x-yaml'             : 'YAML'

(CodeMirror.MODES_ARRAY ||= []).push(mode: k, name: v) for k, v of CodeMirror.MODES

