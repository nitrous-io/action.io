AIO.IdePathView = Em.View.extend
  templateName: 'templates/ide/path'
  content: null

  didClick: ->
    path = @get 'content'
    path.set 'expanded', !path.get('expanded')

