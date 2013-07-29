AIO.Addon = AIO.Resource.extend
  uid: null
  description: null
  state: null

  resourceUrl: '/addons'
  resourceName: 'addon'
  resourceProperties: ['uid', 'description', 'state']

  name: (->
    @get 'uid'
  ).property 'uid'

  # FIXME
  image: "https://partner-portal-8701.s3.amazonaws.com/assets/program/packages@2x-4bcca30e3d6726eea3b6f02b39462a3e.png"
