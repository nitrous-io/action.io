aio.views.editor ||= {}

class aio.views.editor.NavView extends Backbone.View
  template: JST['previous/templates/editor/nav_view']
  id: 'editor-nav'

  render: ->
    @$el.html(this.template())
    this

