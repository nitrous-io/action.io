AIO.BoxTemplateView = Em.View.extend
  templateName: 'templates/boxes/box_template'
  tagName: 'li'
  classNameBindings: ['selected', 'boxTemplate.enabled::coming_soon']

  boxTemplate: null
  box: null

  selected: (->
    @get('boxTemplate.id') == @get('box.boxTemplate.id')
  ).property 'box.boxTemplate'

  click: ->
    boxTemplate = @get 'boxTemplate'
    if boxTemplate.get 'enabled'
      @set 'box.boxTemplate', boxTemplate

