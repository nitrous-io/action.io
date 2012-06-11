aio.views.editor ||= {}
aio.views.editor.console ||= {}

class aio.views.editor.console.ConsoleView extends Backbone.View
  template: JST['editor/console/console_view']
  id: 'editor-console'

  render: ->
    @$el.html(this.template())
    this

  didAddToDOM: ->
    if aio.app.box
      this.$('iframe').attr('src', "/boxes/#{aio.app.box.get('id')}/terminal")

