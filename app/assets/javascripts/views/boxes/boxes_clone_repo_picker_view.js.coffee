AIO.BoxesCloneRepoPickerView = Em.View.extend
  templateName: 'templates/boxes/clone_repo_picker'
  classNames: ['app_page']
  elementId: 'boxes_clone_repo_picker_view'

  didClickNewBox: ->
    @get('controller').cloneIntoNewBox()

  didClickExistingBox: ->
    @get('controller').cloneIntoExistingBox()
