AIO.UploadDialog = Em.ArrayProxy.extend
  path: null
  content: null # [AIO.Upload]
  uploading: false
  completed: (->
    if content = @get 'content'
      content.everyProperty 'completed'
  ).property 'content.@each.completed'

  init: ->
    @_super()
    @set 'content', []

