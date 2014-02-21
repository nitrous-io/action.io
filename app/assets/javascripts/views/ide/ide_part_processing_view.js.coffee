AIO.IdePartProcessingView = Em.View.extend
  templateName: 'templates/ide/part_processing'
  elementId: 'ide_parts_processing_view'

  content: null

  _scrollOutputWindowToBottom: (->
    Em.run.scheduleOnce 'afterRender', this, ->
      @$('.output')?.scrollTop $('.output').height()
  ).observes 'controller.partsSocket.outputStream.content.length'

  title: (->
    return unless content = @get('content')
    "#{content.get('humanized')?.name} #{content.get('version')}"
  ).property 'content.humanized', 'content.version'
