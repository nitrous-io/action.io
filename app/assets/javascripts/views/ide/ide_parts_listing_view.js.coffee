AIO.IdePartListingView = Em.View.extend
  tagName: 'li'
  classNames: ['part_listing_view']
  templateName: 'templates/ide/part_listing'

  content: null
  error: null
  processing: false

  servicesView: false

  installButtonText: (->
    if @get('processing')
      'Installing...'
    else
      'Install'
  ).property 'processing'

  uninstallButtonText: (->
    if @get('processing')
      'Uninstalling...'
    else
      'Uninstall'
  ).property 'processing'

  startButtonText: (->
    if @get('processing')
      'Starting...'
    else
      'Start'
  ).property 'processing'

  stopButtonText: (->
    if @get('processing')
      'Stopping...'
    else
      'Stop'
  ).property 'processing'

  didClickInstall: ->
    @set 'error', null
    @set 'processing', true
    controller = @get('controller')
    name = @get 'content.name'
    controller.install name, (err) =>
      @set 'processing', false
      if err
        @set 'error', err

  didClickUninstall: ->
    @set 'error', null
    @set 'processing', true
    controller = @get('controller')
    name = @get 'content.name'
    controller.uninstall name, (err) =>
      @set 'processing', false
      if err
        @set 'error', err

  didClickStart: ->
    @set 'error', null
    @set 'processing', true
    controller = @get('controller')
    name = @get 'content.name'
    controller.start name, (err) =>
      @set 'processing', false
      if err
        @set 'error', err

  didClickStop: ->
    @set 'error', null
    @set 'processing', true
    controller = @get('controller')
    name = @get 'content.name'
    controller.stop name, (err) =>
      @set 'processing', false
      if err
        @set 'error', err
