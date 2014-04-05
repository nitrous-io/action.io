App.BoxesCloneRepoPickerView = Em.View.extend
  templateName: 'templates/boxes/clone-repo-picker'
  classNames: ['app_page']
  elementId: 'boxes_clone_repo_picker_view'

  didClickNewBox: ->
    @get('controller').cloneIntoNewBox()

  didClickExistingBox: (event) ->
    box = event.context
    @get('controller').cloneIntoExistingBox(box)

  didClickUpgradePage: ->
    App.get('router').transitionTo 'n2o.upgrade'

  didClickBoxesIndex: ->
    App.get('router').transitionTo 'boxes.index'
