App.SettingsTabsView = Em.View.extend
  templateName: 'templates/partials/settings'
  elementId: 'settings_tabs_view'

  activeTab: null
  box: null

  resourcesTabActive: (->
    @get('activeTab') == 'resources'
  ).property 'activeTab'

  domainTabActive: (->
    @get('activeTab') == 'domain'
  ).property 'activeTab'

  snapshotsTabActive: (->
    @get('activeTab') == 'snapshots'
  ).property 'activeTab'

  didClickResources: (event) ->
    unless @get('resourcesTabActive')
      App.get('router').transitionTo 'boxes.resources', id: @get('box.id')

  didClickDomain: (event) ->
    unless @get('domainTabActive')
      App.get('router').transitionTo 'boxes.domains', id: @get('box.id')

  didClickSnapshots: (event) ->
    unless @get('snapshotsTabActive')
      App.get('router').transitionTo 'boxes.snapshotsIndex', id: @get('box.id')

  didClickCancel: (event) ->
    App.get('router').transitionTo 'boxes.index'
