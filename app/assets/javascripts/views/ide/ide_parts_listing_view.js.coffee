AIO.IdePartListingView = Em.View.extend
  tagName: 'li'
  classNames: ['part_listing_view']
  templateName: 'templates/ide/part_listing'

  content: null
  inServicesView: false

  installButtonText: (->
    if @get('content.processing')
      'Installing...'
    else
      'Install'
  ).property 'content.processing'

  uninstallButtonText: (->
    if @get('content.processing')
      'Uninstalling...'
    else
      'Uninstall'
  ).property 'content.processing'

  startButtonText: (->
    if @get('content.processing')
      'Starting...'
    else
      'Start'
  ).property 'content.processing'

  stopButtonText: (->
    if @get('content.processing')
      'Stopping...'
    else
      'Stop'
  ).property 'content.processing'

  didClickInstall: ->
    @get('controller').install @get('content')

  didClickUninstall: ->
    @get('controller').uninstall @get('content')

  didClickStart: ->
    @get('controller').start @get('content')

  didClickStop: ->
    @get('controller').stop @get('content')
