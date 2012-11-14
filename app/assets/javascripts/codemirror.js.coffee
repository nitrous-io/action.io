#= require codemirror/codemirror
#= require codemirror/mode/clike/clike
#  require codemirror/mode/clojure/clojure
#= require codemirror/mode/coffeescript/coffeescript
#= require codemirror/mode/css/css
#= require codemirror/mode/diff/diff
#  require codemirror/mode/ecl/ecl
#  require codemirror/mode/erlang/erlang
#  require codemirror/mode/gfm/gfm
#= require codemirror/mode/go/go
#  require codemirror/mode/groovy/groovy
#  require codemirror/mode/haskell/haskell
#= require codemirror/mode/htmlembedded/htmlembedded
#= require codemirror/mode/htmlmixed/htmlmixed
#= require codemirror/mode/javascript/javascript
#  require codemirror/mode/jinja2/jinja2
#= require codemirror/mode/less/less
#= require codemirror/mode/lua/lua
#= require codemirror/mode/markdown/markdown
#= require codemirror/mode/mysql/mysql
#  require codemirror/mode/ntriples/ntriples
#  require codemirror/mode/pascal/pascal
#= require codemirror/mode/perl/perl
#= require codemirror/mode/php/php
#  require codemirror/mode/pig/pig
#  require codemirror/mode/plsql/plsql
#  require codemirror/mode/properties/properties
#= require codemirror/mode/python/python
#  require codemirror/mode/r/r
#  require codemirror/mode/rpm/changes/changes
#  require codemirror/mode/rpm/spec/spec
#  require codemirror/mode/rst/rst
#= require codemirror/mode/ruby/ruby
#  require codemirror/mode/rust/rust
#= require codemirror/mode/scheme/scheme
#= require codemirror/mode/shell/shell
#  require codemirror/mode/smalltalk/smalltalk
#  require codemirror/mode/smarty/smarty
#  require codemirror/mode/sparql/sparql
#  require codemirror/mode/stex/stex
#  require codemirror/mode/tiddlywiki/tiddlywiki
#  require codemirror/mode/tiki/tiki
#  require codemirror/mode/vbscript/vbscript
#  require codemirror/mode/velocity/velocity
#  require codemirror/mode/verilog/verilog
#= require codemirror/mode/xml/xml
#  require codemirror/mode/xquery/test/testBase
#  require codemirror/mode/xquery/test/testEmptySequenceKeyword
#  require codemirror/mode/xquery/test/testMultiAttr
#  require codemirror/mode/xquery/test/testNamespaces
#  require codemirror/mode/xquery/test/testProcessingInstructions
#  require codemirror/mode/xquery/test/testQuotes
#  require codemirror/mode/xquery/xquery
#= require codemirror/mode/yaml/yaml

# ERB
CodeMirror.defineMIME('text/x-html-erb', name: 'htmlembedded', scriptingModeSpec: 'text/x-ruby')

CodeMirror.MODES =
  'text/plain'              : 'Plain Text'
  'text/x-csrc'             : 'C'
  'text/x-c++src'           : 'C++'
  #'text/x-java'
  #'text/x-csharp'
  #'text/x-scala'
  'text/css'                : 'CSS'
  'text/x-coffeescript'     : 'CoffeeScript'
  'text/x-diff'             : 'Diff'
  #'application/x-aspx'
  #'application/x-jsp'
  'text/x-go'               : 'Go'
  'text/html'               : 'HTML'
  'text/x-html-erb'         : 'HTML (ERB)'
  'application/x-ejs'       : 'HTML (EJS)'
  'text/javascript'         : 'JavaScript'
  'application/json'        : 'JSON'
  'text/x-less'             : 'Less'
  'text/x-lua'              : 'Lua'
  'text/x-markdown'         : 'Markdown'
  'text/x-mysql'            : 'SQL'
  'text/x-perl'             : 'Perl'
  'application/x-httpd-php' : 'PHP'
  #'text/x-php'
  'text/x-python'           : 'Python'
  'text/x-ruby'             : 'Ruby'
  'text/x-scheme'           : 'Scheme'
  'text/x-sh'               : 'Shell Script'
  'application/xml'         : 'XML'
  'text/x-yaml'             : 'YAML'

(CodeMirror.MODES_ARRAY ||= []).push(mode: k, name: v) for k, v of CodeMirror.MODES

