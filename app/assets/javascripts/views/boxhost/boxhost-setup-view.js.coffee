App.BoxhostSetupView = Em.View.extend
  templateName: 'templates/boxhost/setup'
  classNames: ['app_page', 'edit', 'setup']
  elementId: 'boxhost_setup_view'

  didInsertElement: ->
    @_super()
    App.util.mixpanel 'Viewed Boxhost Setup page'
