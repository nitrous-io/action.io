AIO.PlanView = Em.View.extend
  templateName: 'templates/n2o/plan'
  tagName: 'li'
  classNameBindings: ['selected', ':span3']

  plan: null

  selected: (->
    controller = @get 'controller'
    selectedPlan = controller.get('selectedPlan')
    plan = @get 'plan'

    selectedPlan && (selectedPlan.get('id') == plan.get('id'))
  ).property 'controller.selectedPlan'

  isCurrentPlan: (->
    controller = @get 'controller'
    currentPlan = controller.get 'currentPlan'
    plan = @get 'plan'

    currentPlan && (currentPlan.get('id') == plan.get('id'))
  ).property 'controller.currentPlan'

  notStartPlan: (->
    @get('plan.name') != 'Start'
  ).property 'plan.name'

  discounted: (->
    coupon = AIO.currentUser.get('coupon')
    return false unless coupon
    return false if AIO.get('subscription')

    return coupon.percent_off && coupon.percent_off > 0
  ).property 'AIO.currentUser.coupon', 'AIO.subscription'

  discount: (->
    coupon = AIO.currentUser.get('coupon')
    return 0 unless coupon

    percentOff = coupon.percent_off
    price = @get('plan.price')

    price * ( percentOff / 100 )
  ).property 'AIO.currentUser.coupon', 'plan.price'

  formattedPrice: (->
    "$ #{@get('plan.price').toFixed(2)}"
  ).property 'plan.price'

  formattedTotal: (->
    price = @get('plan.price')
    total = price - @get('discount')

    "$ #{total.toFixed(2)}"
  ).property 'discount', 'plan.price'

  click: ->
    controller = @get 'controller'
    plan = @get 'plan'
    controller.set 'selectedPlan', plan
