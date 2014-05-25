App.IdeFileFinderDialogView = App.IdeModalDialogView.extend
  templateName: 'templates/box/ide/file-finder-dialog'
  elementId: 'ide_file_finder_dialog_view'
  contentBinding: 'controller.fileFinderDialog'

  pollerKey: null

  viewDidAppear: ->
    @_super()
    @$('#file_finder_pattern').focus()
    this.setupPoller()

  viewDidDisappear: ->
    @_super()
    if pollerKey = @get('pollerKey')
      Ember.run.cancel(pollerKey)

  keyPress: (e) ->
    switch e.which
      when 38, 40
        'foo'
      when 13
        # TODO
        return false

  setupPoller: ->
    @set 'pollerKey', Ember.run.later(this, (=>
      this.poller()
      this.setupPoller()
    ), 1000)

  poller: ->
    nextSearch = @get('content.pattern')
    if nextSearch != @get('content.currentSearch')
      @get('controller').startFind nextSearch, @get('content.location')
      @set 'content.currentSearch', nextSearch
