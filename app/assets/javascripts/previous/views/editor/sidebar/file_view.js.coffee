aio.views.editor ||= {}
aio.views.editor.sidebar ||= {}

class aio.views.editor.sidebar.FileView extends Backbone.View
  template: JST['previous/templates/editor/sidebar/file_view']
  tagName: 'li'

  initialize: ->
    @model.on('change', this.render, this)

  render: ->
    if @model
      @$el.empty().html(this.template(@model))
      $list = $('<ul>')
      if @model.get('open')
        if children = @model.get('children')
          view = null
          for directory in children.where(directory: true)
            view = new aio.views.editor.sidebar.FileView(model: directory)
            $list.append(view.render().$el)
          for file in children.where(directory: false)
            view = new aio.views.editor.sidebar.FileView(model: file)
            $list.append(view.render().$el)
      this.$el.append($list)
      this.$('> a').on('click', this.openDirectory)
    this

  openDirectory: =>
    console.log "open: #{@model.get('path')}"
    if @model.get('directory')
      aio.app.fsSocket.socket.emit('list', @model.get('path'))

