AIO.SnapshotView = Em.View.extend
  templateName: 'templates/snapshots/snapshot'
  tagName: 'li'
  snapshot: null
  classNameBindings: ['snapshot.expanded']

  didClickTitle: () ->
    @get('snapshot').toggleProperty 'expanded'

