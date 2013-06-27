AIO.BoxesControlView = Em.View.extend
  freeN2OBinding: Em.Binding.oneWay 'AIO.currentUser.free_n2o'

  memoryCost: (->
    unitPrice = AIO.get 'n2o128mbMemory'
    @get('memory') / 128 * unitPrice
  ).property 'memory'

  storageCost: (->
    unitPrice = AIO.get 'n2o250mbStorage'
    @get('storage') / 250 * unitPrice
  ).property 'storage'

  totalCost: (->
    @get('memoryCost') + @get('storageCost')
  ).property 'memoryCost', 'storageCost'

  remainingN2O: (->
    @get('freeN2O') - @get('totalCost')
  ).property 'freeN2O', 'totalCost'

  insufficientN2O: (->
    @get('remainingN2O') < 0
  ).property 'remainingN2O'
