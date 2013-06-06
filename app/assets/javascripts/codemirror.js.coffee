#= require codemirror/codemirror
#= require codemirror/mode/clike/clike
#= require codemirror/mode/clojure/clojure
#= require codemirror/mode/coffeescript/coffeescript
#= require codemirror/mode/css/css
#= require codemirror/mode/diff/diff
#= require codemirror/mode/erlang/erlang
#= require codemirror/mode/go/go
#= require codemirror/mode/htmlembedded/htmlembedded
#= require codemirror/mode/htmlmixed/htmlmixed
#= require codemirror/mode/javascript/javascript
#= require codemirror/mode/jinja2/jinja2
#= require codemirror/mode/less/less
#= require codemirror/mode/lua/lua
#= require codemirror/mode/markdown/markdown
#= require codemirror/mode/perl/perl
#= require codemirror/mode/php/php
#= require codemirror/mode/python/python
#= require codemirror/mode/ruby/ruby
#= require codemirror/mode/sass/sass
#= require codemirror/mode/scheme/scheme
#= require codemirror/mode/shell/shell
#= require codemirror/mode/sql/sql
#= require codemirror/mode/xml/xml
#= require codemirror/mode/yaml/yaml
#= require codemirror/mode/haml/haml

#= require codemirror/addon/search/search
#= require codemirror/addon/search/searchcursor
#= require codemirror/addon/search/match-highlighter
#= require codemirror/addon/dialog/dialog.js

CodeMirror.defineMIME 'text/x-jinja2', name: 'jinja2'

CodeMirror.MODES =
  'text/plain'              : 'Plain Text'
  'text/x-csrc'             : 'C'
  'text/x-c++src'           : 'C++'
  #'text/x-csharp'
  'text/x-clojure'          : 'Clojure'
  'text/x-coffeescript'     : 'CoffeeScript'
  'text/css'                : 'CSS'
  'text/x-diff'             : 'Diff'
  'text/x-erlang'           : 'Erlang'
  #'application/x-aspx'
  'text/x-go'               : 'Go'
  'text/x-haml'             : 'Haml'
  'text/html'               : 'HTML'
  'application/x-ejs'       : 'HTML (ejs)'
  'application/x-erb'       : 'HTML (erb)'
  'text/x-java'             : 'Java'
  'text/javascript'         : 'JavaScript'
  'text/x-jinja2'           : 'Jinja2'
  'application/json'        : 'JSON'
  'application/x-jsp'       : 'JSP'
  'text/x-less'             : 'LESS'
  'text/x-lua'              : 'Lua'
  'text/x-markdown'         : 'Markdown'
  'text/x-perl'             : 'Perl'
  'application/x-httpd-php' : 'PHP'
  'text/x-python'           : 'Python'
  'text/x-ruby'             : 'Ruby'
  'text/x-sass'             : 'Sass'
  'text/x-scala'            : 'Scala'
  'text/x-scheme'           : 'Scheme'
  'text/x-scss'             : 'SCSS'
  'text/x-sh'               : 'Shell Script'
  'text/x-sql'              : 'SQL'
  'application/xml'         : 'XML'
  'text/x-yaml'             : 'YAML'

(CodeMirror.MODES_ARRAY ||= []).push(mode: k, name: v) for k, v of CodeMirror.MODES

