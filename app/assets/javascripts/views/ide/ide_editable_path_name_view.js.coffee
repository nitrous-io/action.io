AIO.IdeEditablePathNameView = Em.View.extend
  templateName: 'templates/ide/editable_path_name'
  classNames: ['ide_editable_path_name_view']

  path: null
  newPathName: ''

  didFinishEditing: ->
    path = @get 'path'
    if path.get 'new'
      @get('controller').saveNewPath path, @get('newPathName')
    else
      @get('controller').applyRenamedPath path, @get('newPathName')

  didCancelEditing: ->
    path = @get 'path'
    if path.get 'new'
      @get('controller').cancelNewPath path
    else
      @get('controller').resetRenamedPath path

AIO.IdeEditablePathNameTextField = Em.TextField.extend
  finished: false

  didBecomeDisabled: (->
    if @get 'disabled'
      @$().blur()
  ).observes 'disabled'

  didInsertElement: ->
    @_super()
    parentView = @get('parentView')
    path = parentView.get("path")
    pathName =  unless path?.get('new') then path.get("name") else "Untitled"
    @set "placeholder", pathName
    @$().focus()

  insertNewline: ->
    if @get('value').trim().length > 0
      this.doneEditing()
    else
      this.cancelEditing()

  focusOut: ->
    this.insertNewline()

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

