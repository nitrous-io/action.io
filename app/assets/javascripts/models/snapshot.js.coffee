AIO.Snapshot = AIO.Resource.extend
  name: null
  state: null
  user_id: null
  box_id: null
  public: null
  created_at: null
  completed_at: null

  resourceUrl: '/snapshots'
  resourceName: 'snapshot'
  resourceProperties: ['name', 'box_id', 'public']

  validations:
    name: (v) -> "can't be blank" unless v && v.length > 0

  box: (->
    AIO.get('router.boxesController').findById @get('box_id')
  ).property 'box_id'

  description: (->
    if @get 'box'
      "#{@get 'name'} of box #{@get 'box.name'} (created #{@get 'humanizedCreatedAt'})"
    else
      "#{@get 'name'} created #{@get 'humanizedCreatedAt'}"
  ).property 'name', 'humanizedCreatedAt', 'box'

  humanizedCreatedAt: AIO.util.humanizedTimeProperty('created_at')

  humanizedCompletedAt: AIO.util.humanizedTimeProperty('completed_at')

  queued: (->
    @get('state') == 'queued'
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

AIO.SnapshotsCollection = Em.ArrayProxy.extend Em.SortableMixin,
  content: null
  sortProperties: ['created_at']
  sortAscending: false
