AIO.N2oBonusItemView = Em.View.extend
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
  disabled: false

  click: ->
    disabled = @get 'disabled'
    completed = @get 'completed'

    unless disabled || completed
      if route = @get 'route'
        AIO.get('router').transitionTo route
      else if url = @get 'url'
        window.location = url
