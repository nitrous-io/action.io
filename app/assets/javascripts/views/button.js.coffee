AIO.Button = Em.View.extend Em.TargetActionSupport,
  tagName: 'button'
  text: 'button'
  template: Em.Handlebars.compile '{{view.text}}'
  classNames: ['btn']

  attributeBindings: ['disabled', 'tabindex']
  disabled: false

  click: ->
    this.triggerAction()
    false

