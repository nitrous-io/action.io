AIO.BoxTemplateView = Em.View.extend
  templateName: 'templates/boxes/box_template'
  tagName: 'li'
  classNameBindings: ['selected', 'boxTemplate.enabled::coming_soon']

  boxTemplate: null
  box: null

  selected: (->
    @get('boxTemplate.id') == @get('box.box_template_id')
  ).property 'box.box_template_id'

  click: ->
    boxTemplate = @get 'boxTemplate'
    if boxTemplate.get 'enabled'
      mixpanel?.track 'box_template:click', boxTemplate.get('id')
      @set 'box.box_template_id', boxTemplate.get('id')
