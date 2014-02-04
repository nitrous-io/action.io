AIO.Snapshot = AIO.Resource.extend
  name: null
  user_id: null
  box_id: null

  resourceUrl: '/snapshots'
  resourceName: 'snapshot'
  resourceProperties: ['name', 'user_id', 'box_id']

  validations:
    name: (v) -> "can't be blank" unless v && v.length > 0

  box: (->
    AIO.get('router.boxesController').findById @get('box_id')
  ).property 'box_id'
