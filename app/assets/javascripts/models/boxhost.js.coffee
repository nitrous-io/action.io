#= require ./base-model

App.Boxhost = klass = App.BaseModel.extend
  name: Em.attr()
  state: Em.attr()
  dedicated: Em.attr()
  location_id: Em.attr(Number)
  owner: Em.belongsTo('App.CurrentUser', key: 'owner_id')
  boxhostPlan: Em.belongsTo('App.BoxhostPlan', key: 'boxhost_plan_id')

  validations:
    name: (v) -> "can't be blank" unless v && v.length > 0
    location_id: (v) -> "needs to be selected" unless v

  location: (->
    App.Location.findById @get('location_id')
  ).property 'location_id'

  unprovisioned: (->
    @get('state') == 'born'
  ).property 'state'

klass.reopenClass
  rootKey: 'boxhost'
  collectionKey: 'boxhosts'
  url: '/boxhosts'
