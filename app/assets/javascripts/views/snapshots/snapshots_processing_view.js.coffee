AIO.SnapshotsProcessingView = Em.View.extend
  templateName: 'templates/snapshots/processing'
  classNames: ['app_page', 'snapshot']
  elementId: 'snapshots_processing_view'

  title: 'Snapshotting'
  titleInterval: null

  didInsertElement: ->
    @_super()
    titleCounter = 0
    @set 'titleInterval', window.setInterval =>
      @set 'title', 'Provisioning' + '...'.substring(0, ++titleCounter % 4)
    , 1000

  willDestroyElement: ->
    @_super()
    window.clearInterval @get 'titleInterval'
    @set 'titleInterval', null
