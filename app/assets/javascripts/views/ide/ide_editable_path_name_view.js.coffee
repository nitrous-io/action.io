AIO.IdeEditablePathNameView = Em.View.extend
  templateName: 'templates/ide/editable_path_name'
  classNames: ['ide_editable_path_name_view']

  path: null
  newPathName: ''

  didFinishEditing: ->
    path = @get 'path'
    if path.get 'new'
      mixpanel?.track 'editable_pathname:finish'
      @get('controller').saveNewPath path, @get('newPathName')

  didCancelEditing: ->
    path = @get 'path'
    if path.get 'new'
      mixpanel?.track 'editable_pathname:cancel'
      @get('controller').cancelNewPath path

AIO.IdeEditablePathNameTextField = Em.TextField.extend
  finished: false

  didBecomeDisabled: (->
    if @get 'disabled'
      @$().blur()
  ).observes 'disabled'

  didInsertElement: ->
    @_super()
    mixpanel?.track 'editable_pathname:insert'
    @$().focus()

  insertNewline: ->
    if @get('value').length > 0
      this.doneEditing()
    else
      this.cancelEditing()

  focusOut: ->
    this.cancelEditing()

  keyDown: (event) ->
    this.cancelEditing() if event.keyCode == 27 # escape key

  doneEditing: ->
    unless @get 'finished'
      @set 'finished', true
      @set 'disabled', true
      @get('parentView').didFinishEditing()

  cancelEditing: ->
    unless @get 'finished'
      @set 'finished', true
      @set 'disabled', true
      @get('parentView').didCancelEditing()
