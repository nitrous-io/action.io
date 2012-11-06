untitledCount = 0

AIO.Document = Em.Object.extend
  active: false
  focused: false
  content: ''
  path: null

  title: (->
    @get('path.name') || "Untitled #{untitledCount += 1}"
  ).property 'path.name'

