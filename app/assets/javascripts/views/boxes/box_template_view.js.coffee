AIO.BoxTemplateView = Em.View.extend
  templateName: 'templates/boxes/box_template'
  tagName: 'li'
  classNameBindings: ['selected', 'boxTemplate.enabled::coming_soon']

  boxTemplate: null
  box: null

  didInsertElement: ->
    @$('a.stackLabel').on 'click', (event) =>
      event.preventDefault()

  willDestroyElement: ->
    @$('a.stackLabel').off 'click'

  selected: (->
    @get('boxTemplate.id') == @get('box.box_template_id')
  ).property 'box.box_template_id'

  click: ->
    boxTemplate = @get 'boxTemplate'
    if boxTemplate.get 'enabled'
      @set 'box.box_template_id', boxTemplate.get('id')

