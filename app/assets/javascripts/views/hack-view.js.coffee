App.HackView = Em.View.extend
  templateName: 'templates/hack'
  classNames: ['app_page']
  elementId: 'hack-view'

  didInsertElement: ->
    @_super()
    App.util.mixpanel 'Viewed Box Picker for Cloning Repo'

  didClickExistingBox: (box) ->
    @get('controller').cloneIntoExistingBox(box)

  didClickUpgradePage: ->
    App.get('router').transitionTo 'n2o.upgrade'

  didClickBoxesIndex: ->
    App.get('router').transitionTo 'boxes.index'
