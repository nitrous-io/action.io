AIO.PartListingView = Em.View.extend
  tagName: 'li'
  classNames: ['part_listing_view']
  templateName: 'templates/components/part_listing'

  content: null
  error: null
  processing: false

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

  didClickInstall: ->
    @set 'error', null
    @set 'processing', true
    controller = @get('controller')
    name = @get 'content.name'
    controller.install name, (err, output) =>
      @set 'processing', false
      if err
        @set 'error', err

  didClickUninstall: ->
    @set 'error', null
    @set 'processing', true
    controller = @get('controller')
    name = @get 'content.name'
    controller.uninstall name, (err, output) =>
      @set 'processing', false
      if err
        @set 'error', err
