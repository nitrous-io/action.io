AIO.BoxView = Em.View.extend
  templateName: 'templates/boxes/box'
  tagName: 'li'
  box: null
  classNameBindings: ['box.expanded']

  didClickBoxTitle: (event) ->
    @box.toggleProperty 'expanded'

  didClickIDE: (event) ->
    @get('controller').transitionToRoute 'ide', @box

  didClickProvisioning: (event) ->
    @get('controller').transitionToRoute 'boxes.provisioning', @box

AIO.BoxTextField = Em.TextField.extend
  classNames: ['box_text_field']

  didInsertElement: ->
    @_super()
    @$().attr 'readonly', true

  click: ->
    @$().select()
