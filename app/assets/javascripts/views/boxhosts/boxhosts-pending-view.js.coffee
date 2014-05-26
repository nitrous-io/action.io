App.BoxhostsPendingView = Em.View.extend
  templateName: 'templates/boxhosts/pending'
  classNames: ['app_page', 'pending']
  elementId: 'boxhosts_pending_view'

  didInsertElement: ->
    @_super()
    App.util.mixpanel 'Viewed Boxhosts Pending Setup page'
