untitledCount = 0

AIO.Document = Em.Resource.extend
  active                   : false
  focused                  : false
  content                  : ''
  lastSavedContent         : ''
  path                     : null
  pathname                 : null
  syncLock                 : null # check to not sync if the document will eventually sync later
  resourceName             : 'document'
  resourceProperties       : ['pathname']
  fileSystemBinding        : Em.Binding.oneWay 'AIO.router.ideController.sftpSocket'
  fileSystemReadyBinding   : Em.Binding.oneWay 'fileSystem.started'

  resourceUrl: (->
    if contentId = AIO.get 'router.ideController.content.id'
      "/boxes/#{contentId}/documents"
  ).property 'router.ideController.content.id'

  title: (->
    @get('path.name') || "Untitled #{untitledCount += 1}"
  ).property 'path.name'

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
    @notifyPropertyChange('path.absolutePath') if @get('path.absolutePath')

  cleanDidChange: (->
    clearTimeout(@get('syncLock')) if @get('syncLock')
    @syncLock = setTimeout =>
      @saveContent()
      @syncLock = null
    , AIO.Document.SYNC_TIMEOUT
  ).observes 'clean'

  absolutePathDidChange: (->
    @set 'pathname', @get('path.absolutePath')
  ).observes 'path.absolutePath'

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
    return unless @get 'fileSystemReady'
    if path = @get('path')
      if fileSystem = @get 'fileSystem'
        path.incrementProperty 'loadCount'
        fileSystem.writeFile path.get('absolutePath'), @get('content'), (err, absolutePath) =>
          path.decrementProperty 'loadCount'
          @set 'lastSavedContent', @get('content')

  # load and replace the current content of the file with the content from box
  loadContent: () ->
    return unless @get 'fileSystemReady'
    if path = @get('path')
      if fileSystem = @get 'fileSystem'
        path.incrementProperty 'loadCount'
        fileSystem.fetchFileContent path.get('absolutePath'), (err, absolutePath, content) =>
          path.decrementProperty 'loadCount'
          @set 'content', content

  # Sync state of this document to the server
  # This accepts a callback that will handle post-logic of the save after the
  # ajax returns.
  # The callback will have two arguments:
  # err - is null when the save success or an error message when the save fails
  # document - current instance of document object.
  sync: (cb) ->
    return unless @get('path')
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
    return unless @get('path')
    success = => cb? null, @
    error = (err) => cb? err, @
    @destroyResource().done(success).fail(error)

  # recalculate the path whenever the pathname changed or there are new
  # contents being added into the sidebar.
  # This is used to repopulate `path` attribute for a document that is fetched
  # from the server's list of `Document`
  pathDidFind: (->
    pathname = @get('pathname')
    if !@get('path') && pathname
      path = _.find AIO.get("router.ideSidebarController.content"), (path) ->
        path.get("absolutePath") == pathname
      return unless path
      @set 'path', path
      @loadContent()
  ).observes 'pathname', 'AIO.router.ideSidebarController.content.@each'

AIO.Document.SYNC_TIMEOUT = 1000
