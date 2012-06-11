aio.views.editor ||= {}
aio.views.editor.editor ||= {}

class aio.views.editor.editor.EditorView extends Backbone.View
  template: JST['editor/editor/editor_view']
  id: 'editor-editor'

  render: ->
    @$el.html(this.template())
    this

  didAddToDOM: ->
    @ace = ace.edit('editor')
    @ace.setShowPrintMargin(false)
    @ace.setTheme('ace/theme/railscasts')
    @ace.getSession().setMode('ace/mode/ruby')
    @ace.getSession().setTabSize(2)

