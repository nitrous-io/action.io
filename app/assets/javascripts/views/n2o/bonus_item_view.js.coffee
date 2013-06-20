AIO.N2oBonusItemView = Em.View.extend
  templateName: 'templates/n2o/bonus_item'
  classNames: ['n2o_bonus_item_view']
  classNameBindings: ['completed:completed', 'disabled']
  tagName: 'li'

  name: null
  icon: null
  completed: null
  reward: null
  disabled: false
