AIO.IdePartListingView = Em.View.extend
  tagName: 'li'
  classNames: ['part_listing_view']
  templateName: 'templates/ide/part_listing'

  content: null

  installButtonText: (->
    if @get('content.installing')
      'Installing...'
    else
      'Install'
  ).property 'content.installing'

  uninstallButtonText: (->
    if @get('content.uninstalling')
      'Uninstalling...'
    else
      'Uninstall'
  ).property 'content.uninstalling'

  startButtonText: (->
    if @get('content.starting')
      'Starting...'
    else
      'Start'
  ).property 'content.starting'

  stopButtonText: (->
    if @get('content.stopping')
      'Stopping...'
    else
      'Stop'
  ).property 'content.stopping'

  didClickInstall: ->
    @get('controller').install @get('content')

  didClickUninstall: ->
    @get('controller').uninstall @get('content')

  didClickStart: ->
    @get('controller').start @get('content')

  didClickStop: ->
    @get('controller').stop @get('content')
