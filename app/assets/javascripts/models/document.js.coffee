untitledCount = 0

AIO.Document = Em.Resource.extend
  active: false
  focused: false
  content: ''
  lastSavedContent: ''
  path: null

  resourceName: 'document'
  resourceProperties : ['path', 'content', 'dirty']
  resourceUrl: (->
    if contentId = AIO.get 'router.ideController.content.id'
      "/boxes/#{contentId}/documents"
  ).property 'router.ideController.content.id'

  # hack to workaround ember-rest inability to handle dynamic resourceUrl
  _resourceUrl: () ->
    url = @get("resourceUrl")
    id = @_resourceId()
    if id then "#{url}/#{id}" else url

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

  # Sync state of this document to the server
  # This accepts a callback that will handle post-logic of the save after the
  # ajax returns.
  # The callback will have two arguments:
  # err - is null when the save success or an error message when the save fails
  # document - current instance of document object.
  sync: (cb) ->
    success = => cb null, @
    error = (err) => cb err, @
    @saveResource().done(success).fail(error)
