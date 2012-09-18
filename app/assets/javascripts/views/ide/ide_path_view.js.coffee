AIO.IdePathView = Em.View.extend
  templateName: 'templates/ide/path'
  path: null

  didClick: ->
    path = @get 'path'
    @get('controller').openPath path

