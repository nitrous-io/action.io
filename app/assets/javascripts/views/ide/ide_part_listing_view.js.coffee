AIO.IdePartListingView = Em.View.extend
  tagName: 'li'
  classNames: ['part_listing_view']
  templateName: 'templates/ide/part_listing'

  content: null

  didClickInstall: ->
    @get('controller').install @get('content')

  didClickUninstall: ->
    @get('controller').uninstall @get('content')

  didClickStart: ->
    @get('controller').start @get('content')

  didClickStop: ->
    @get('controller').stop @get('content')
