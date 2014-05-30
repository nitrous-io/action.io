App.IdeFileFinderDialogView = App.IdeModalDialogView.extend
  templateName: 'templates/box/ide/file-finder-dialog'
  elementId: 'ide_file_finder_dialog_view'
  contentBinding: 'controller.fileFinderDialog'

  pollerKey: null

  init: ->
    @_super.apply this, arguments
    @set 'data-backdrop', 'true'

  viewDidAppear: ->
    @_super()

    # Workaround for Chrome 35 where the focus switches
    # to document.body after the focus() call below is
    # run.  Restore focus to text field on blur only
    # _once_ to handle this situation.
    @$('#file_finder_pattern').one 'blur', =>
      if document.activeElement == document.body
        @$('#file_finder_pattern').focus()

    @$('#file_finder_pattern').focus()
    this.setupPoller()

  viewDidDisappear: ->
    @_super()
    if pollerKey = @get('pollerKey')
      Ember.run.cancel(pollerKey)

  keyDown: (e) ->
    suppress = ->
      e.preventDefault()
      e.stopPropagation()

    switch e.which
      when 38 # up
        suppress()
        @get('content')?.decrementIndex()
      when 40 # down
        suppress()
        @get('content')?.incrementIndex()
      when 10, 13
        suppress()
        if filename = @get('content.selectedFile.filename')
          this.didClickResult(filename)

  setupPoller: ->
    @set 'pollerKey', Ember.run.later(this, (=>
      this.poller()
      this.setupPoller()
    ), 200)

  poller: ->
    nextSearch = @get('content.pattern')
    if nextSearch != @get('content.currentSearch')
      @get('controller').startFind nextSearch, @get('content.basePath')
      @set 'content.currentSearch', nextSearch

  didClickResult: (filename) ->
    # filename will be relative to home directory
    path = App.Path.create absolutePath: filename
    if sidebar = @get 'controller.controllers.ideSidebar'
      sidebar.openPath path,
        done: =>
          this.hide()
        source: 'filefinder'

