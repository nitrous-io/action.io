AIO.Button = Em.View.extend Em.TargetActionSupport,
  tagName: 'button'
  text: 'button'
  template: Em.Handlebars.compile '{{view.text}}'

  attributeBindings: ['disabled', 'tabindex']
  disabled: false

  click: ->
    this.triggerAction()
    false

