AIO.Snapshot = AIO.Resource.extend
  name: null
  state: null
  user_id: null
  box_id: null
  public: null
  created_at : null

  resourceUrl: '/snapshots'
  resourceName: 'snapshot'
  resourceProperties: ['name', 'box_id', 'public']

  validations:
    name: (v) -> "can't be blank" unless v && v.length > 0

  box: (->
    AIO.get('router.boxesController').findById @get('box_id')
  ).property 'box_id'

  humanizedCreatedAt: AIO.util.humanizedTimeProperty('created_at')

  requested: (->
    @get('state') == 'requested'
  ).property 'state'

  initiated: (->
    @get('state') == 'initiated'
  ).property 'state'

  completed: (->
    @get('state') == 'completed'
  ).property 'state'

  failed: (->
    @get('state') == 'failed'
  ).property 'state'

  deleted: (->
    @get('state') == 'deleted'
  ).property 'state'
