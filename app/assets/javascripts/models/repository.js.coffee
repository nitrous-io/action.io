AIO.Repository = AIO.Resource.extend
  box_id: null
  name: null
  full_name: null
  clone_url: null
  state: null
  private: null
  cloned_at: null
  created_at: null

  resourceUrl: '/repositories'
  resourceName: 'repository'
  resourceProperties: ['clone_url', 'box_id']

  box: (->
    AIO.get('router.boxesController').findById @get('box_id')
  ).property 'box_id'
