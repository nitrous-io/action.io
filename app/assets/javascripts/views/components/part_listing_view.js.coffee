AIO.PartListingView = Em.View.extend
  classNames: ['part_listing_view']
  templateName: 'templates/components/part_listing'

  content: null
  error: null

  installed: false
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
    @set 'processing', true
    controller = @get('controller')
    name = @get 'content.name'
    controller.install name, (err, output) =>
      @set 'processing', false
      unless err
        @set 'installed', true
      else
        @set 'error', err

  didClickUninstall: ->
    @set 'processing', true
    controller = @get('controller')
    name = @get 'content.name'
    controller.uninstall name, (err, output) =>
      @set 'processing', false
      unless err
        @set 'installed', false
      else
        @set 'error', err
