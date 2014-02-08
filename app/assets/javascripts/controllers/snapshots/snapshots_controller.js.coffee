AIO.SnapshotsController = AIO.ResourceController.extend
  resourceType: AIO.Snapshot
  jsonRoot: 'snapshots'
  sortProperties: ['created_at']
  sortAscending: false
