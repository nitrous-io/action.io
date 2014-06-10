App.BoxhostPlansView = Em.View.extend
  templateName: 'templates/boxhost-plans/index'
  classNames: ['app_page', 'index']
  elementId: 'boxhost_plans_index_view'

  didInsertElement: ->
    @_super()
    App.util.mixpanel 'Viewed Boxhost Plans Index'
