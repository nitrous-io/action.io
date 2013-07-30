AIO.Addon = AIO.Model.extend
  uid: null
  description: null
  state: null
  image: "https://partner-portal-8701.s3.amazonaws.com/assets/program/packages@2x-4bcca30e3d6726eea3b6f02b39462a3e.png"
  
  name: (->
    @get 'uid'
  ).property 'uid'

AIO.Addon.reopenClass
  resourceUrl: '/addons'
  resourceName: 'addon'
  jsonRoot: 'addons'
