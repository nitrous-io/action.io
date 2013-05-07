untitledCount = 0

AIO.Document = Em.Object.extend
  active: false
  focused: false
  content: ''
  path: null
  contentType: null
  clean: true

  init: (attrs={}) ->
    @_super(attrs)

  title: (->
    @get('path.name') || "Untitled #{untitledCount += 1}"
  ).property 'path.name'

  isImageFile: (->
    @get('contentType')?.match /^image/
  ).property 'contentType'

  tooltip: (->
    @get('path.absolutePath') || @get('title')
  ).property 'path.absolutePath'
