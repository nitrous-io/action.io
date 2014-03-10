AIO.SettingsTabsView = Em.View.extend
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
      AIO.get('router').transitionTo 'boxes.resources', id: @get('box.id')

  didClickDomain: (event) ->
    unless @get('domainTabActive')
      AIO.get('router').transitionTo 'boxes.domains', id: @get('box.id')

  didClickSnapshots: (event) ->
    unless @get('snapshotsTabActive')
      AIO.get('router').transitionTo 'boxes.snapshotsIndex', id: @get('box.id')

  didClickCancel: (event) ->
    AIO.get('router').transitionTo 'boxes.index'
