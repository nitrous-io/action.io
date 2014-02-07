AIO.Snapshot = AIO.Resource.extend
  name: null
  user_id: null
  box_id: null
  public: null

  resourceUrl: '/snapshots'
  resourceName: 'snapshot'
  resourceProperties: ['name', 'box_id', 'public']

  validations:
    name: (v) -> "can't be blank" unless v && v.length > 0

  box: (->
    AIO.get('router.boxesController').findById @get('box_id')
  ).property 'box_id'
