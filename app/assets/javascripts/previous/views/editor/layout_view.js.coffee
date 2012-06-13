aio.views.editor ||= {}

class aio.views.editor.LayoutView extends Backbone.View
  template: JST['previous/templates/editor/layout_view']
  id: 'editor-layout'

  initialize: ->
    @navView = new aio.views.editor.NavView
    @sidebarView = new aio.views.editor.sidebar.SidebarView
    @editorView = new aio.views.editor.editor.EditorView
    @consoleView = new aio.views.editor.console.ConsoleView

  render: ->
    @$el.html(this.template())
    this.$('#editor-nav').replaceWith(@navView.render().$el)
    this.$('#editor-sidebar').replaceWith(@sidebarView.render().$el)
    this.$('#editor-editor').replaceWith(@editorView.render().$el)
    this.$('#editor-console').replaceWith(@consoleView.render().$el)
    this

  didAddToDOM: ->
    @sidebarView.didAddToDOM()
    @editorView.didAddToDOM()
    @consoleView.didAddToDOM()

