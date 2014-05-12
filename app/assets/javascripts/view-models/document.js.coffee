untitledCount = 0

App.Document = Em.Object.extend
  active: false
  focused: false
  content: ''
  path: null
  contentType: null
  clean: true

  findTrigger: null
  findNextTrigger: null
  findPrevTrigger: null
  replaceTrigger: null
  replaceAllTrigger: null

  foldCodeTrigger: null
  unfoldCodeTrigger: null
  toggleCommentTrigger: null

  title: (->
    @get('path.name') || "Untitled #{untitledCount += 1}"
  ).property 'path.name'

  isImageFile: (->
    @get('contentType')?.match /^image/
  ).property 'contentType'

  tooltip: (->
    @get('path.absolutePath') || @get('title')
  ).property 'path.absolutePath'
