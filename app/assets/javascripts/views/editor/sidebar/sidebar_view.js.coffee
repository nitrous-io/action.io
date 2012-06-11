aio.views.editor ||= {}
aio.views.editor.sidebar ||= {}

class aio.views.editor.sidebar.SidebarView extends Backbone.View
  template: JST['editor/sidebar/sidebar_view']
  id: 'editor-sidebar'

  initialize: ->
    @rootFileView = new aio.views.editor.sidebar.FileView(model: new aio.models.File(name: '~', path: '/', open: true))

  render: ->
    @$el.html(this.template())
    this.$('.tree > ul').append(@rootFileView.render().$el) if @rootFileView
    this

  didAddToDOM: ->
    if aio.app.box
      aio.app.fsSocket = new aio.sockets.FSSocket aio.app.wsServerURI, aio.app.box.get('id'), (socket) =>
        socket.on 'start', (err) =>
          return if err
          socket.emit('list', @rootFileView.model.get('path'))

        socket.on 'list', (err, path, fileList) =>
          file = @rootFileView.model.findFile(path)
          file.parseList(fileList)
          file.set(open: true)

