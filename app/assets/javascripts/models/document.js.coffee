untitledCount = 0

AIO.Document = Em.Object.extend
  active: false

  init: ->
    @_super()
    unless @get 'title'
      @set 'title', "Untitled #{untitledCount += 1}"

