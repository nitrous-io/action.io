untitledCount = 0

AIO.Document = Em.Object.extend
  active: false
  focused: false
  content: ''
  lastSavedContent: ''
  path: null

  init: (attrs={}) ->
    @_super(attrs)
    @set 'lastSavedContent', @get('content')

  title: (->
    @get('path.name') || "Untitled #{untitledCount += 1}"
  ).property 'path.name'

  clean: (->
    @get('lastSavedContent') == @get('content')
  ).property 'content', 'lastSavedContent'

  closeButtonClass: (->
    if @get('clean')
      'icon-remove'
    else
      'icon-asterisk'
  ).property 'clean'

