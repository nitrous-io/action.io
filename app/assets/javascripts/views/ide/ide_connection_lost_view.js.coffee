AIO.IdeConnectionLostView = Em.View.extend
  templateName: 'templates/ide/connection_lost'
  elementId: 'ide_connection_lost'

  didClickRetry: ->
    AIO.util.mixpanel 'Clicked Retry IDE Connection'
    window.location.reload()




