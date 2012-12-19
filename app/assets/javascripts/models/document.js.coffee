untitledCount = 0

AIO.Document = Em.Resource.extend
  active                   : false
  focused                  : false
  loaded                   : null
  content                  : ''
  lastSavedContent         : ''
  pathname                 : null # absolute path of the document
  syncLock                 : null # check to not sync if the document will eventually sync later
  loadCount                : 0    # mainly used to check for saving status / able to save etc
  resourceName             : 'document'
  resourceProperties       : ['pathname']
  fileSystemBinding        : Em.Binding.oneWay 'AIO.router.ideController.sftpSocket'
  fileSystemReadyBinding   : Em.Binding.oneWay 'fileSystem.started'

  resourceUrl: (->
    if contentId = AIO.get 'router.ideController.content.id'
      "/boxes/#{contentId}/documents"
  ).property 'router.ideController.content.id'

  title: (->
    if pathname = @get('pathname')
      AIO.Path.getFilename pathname
    else
      "Untitled #{untitledCount += 1}"
  ).property 'pathname'

  clean: (->
    @get('lastSavedContent') == @get('content')
  ).property 'content', 'lastSavedContent'

  # hack to workaround ember-rest inability to handle dynamic resourceUrl
  _resourceUrl: () ->
    url = @get("resourceUrl")
    id = @_resourceId()
    if id then "#{url}/#{id}" else url

  init: (attrs={}) ->
    @_super(attrs)
    @set 'lastSavedContent', @get('content')

  focusedDidChange: (->
    if @get('focused') == false
      @saveContent()
  ).observes 'focused'

  closeButtonClass: (->
    if @get('clean')
      'icon-remove'
    else
      'icon-asterisk'
  ).property 'clean'

  # save current content of the document to the box
  # this only save documents that have specified path (i.e.e has been saved
  # into the file system on the host), which meant that it ignores the unsaved
  # documents
  saveContent: () ->
    return unless @get 'canBeChanged'
    fileSystem = @get 'fileSystem'
    pathname = @get 'pathname'
    if @get('loadCount') < 1
      @incrementProperty 'loadCount'
      fileSystem.writeFile pathname, @get('content'), (err, absolutePath) =>
        @decrementProperty 'loadCount'
        @set 'lastSavedContent', @get('content')

  # load and replace the current content of the file with the content from box
  loadContent: (cb) ->
    return unless @get 'canBeChanged'
    fileSystem = @get 'fileSystem'
    pathname = @get 'pathname'
    @incrementProperty 'loadCount'
    fileSystem.fetchFileContent pathname, (err, absolutePath, content) =>
      @decrementProperty 'loadCount'
      unless err
        @set 'content', content
        @set 'lastSavedContent', content
        @set 'loaded', true
        cb? this

  # Sync state of this document to the server
  # This accepts a callback that will handle post-logic of the save after the
  # ajax returns.
  # The callback will have two arguments:
  # err - is null when the save success or an error message when the save fails
  # document - current instance of document object.
  sync: (cb) ->
    return unless @get('pathname')
    success = => cb? null, @
    error = (err) => cb? err, @
    @saveResource().done(success).fail(error)

  # Remove a document on the server
  # This accepts a callback that will handle post-logic of the save after the
  # ajax returns.
  # The callback will have two arguments:
  # err - is null when the save success or an error message when the save fails
  # document - current instance of document object.
  destroy: (cb) ->
    return unless @get('pathname')
    success = => cb? null, @
    error = (err) => cb? err, @
    @destroyResource().done(success).fail(error)

  # this will be called whenever the file system is ready and only if the
  # content is empty. This case should happen only once when the file is synced
  # from server when the ide is starting and not opened by the user
  prepareContentWhenReady: (->
    @loadContent() if @get 'canBeChanged'
  ).observes 'canBeChanged'

  # Check if the document can be saved to / loaded from the file system
  # Returns boolean of course
  canBeChanged: (->
    !!(@get('fileSystemReady') && @get('fileSystem') && @get('pathname'))
  ).property 'fileSystemReady', 'fileSystem', 'pathname'
