AIO.IdePathView = Em.View.extend
  templateName: 'templates/ide/path'
  content: null

  didClick: ->
    path = @get 'content'
    @get('controller').openPath path

