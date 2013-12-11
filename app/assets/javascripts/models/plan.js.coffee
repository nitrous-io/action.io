AIO.Plan = AIO.Resource.extend
  name              : null
  price             : null
  interval          : null
  highlight         : null
  display_order     : null
  n2o_amount        : null

  priceFormatted: (->
    price = @get 'price'
    "$#{price.toFixed(2)}"
  ).property 'price'

  featuresArray: (->
    if features = @get 'features'
      $.trim(features).split '|'
  ).property 'features'
