AIO.Snapshot = AIO.Resource.extend
  name             : null
  description      : null
  visibility       : null
  box_id           : null
  owner_id         : null

  resourceUrl: '/sanpshots'
  resourceName: 'snapshot'
  resourceProperties: ['name', 'description', 'visibility', 'box_id', 'owner_id']

  validations:
    name: (v) -> "can't be blank" unless v && v.length > 0

  owner: (->
    AIO.get("router.applicationController.currentUser")
  ).property()
