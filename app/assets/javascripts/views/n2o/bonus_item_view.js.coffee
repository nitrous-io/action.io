AIO.N2oBonusItemView = Em.View.extend Em.TargetActionSupport,
  templateName: 'templates/n2o/bonus_item'
  classNames: ['n2o_bonus_item_view']
  classNameBindings: ['completed:completed', 'disabled']
  tagName: 'li'

  name: null
  icon: null
  completed: null
  reward: 0
  route: null
  url: null
  enabled: true

  disabled: (->
    !@get('enabled')
  ).property 'enabled'

  click: ->
    disabled = @get 'disabled'
    completed = @get 'completed'

    unless disabled || completed
      if route = @get 'route'
        AIO.get('router').transitionTo route
      else if url = @get 'url'
        window.location = url
      else
        this.triggerAction()
