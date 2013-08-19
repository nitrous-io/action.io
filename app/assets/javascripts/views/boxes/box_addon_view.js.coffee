AIO.BoxAddonView = Em.View.extend
  templateName: 'templates/boxes/box_addon'
  tagName: 'div'
  addon: null
  box: null

# controller is BoxesEditController
AIO.BoxAddonPlanProvisionButton = Em.View.extend
  tagName: "button"
  template: Em.Handlebars.compile("Provision")
  classNames: ["btn", "btn-danger"]

  addonPlan: null

  click: ->
    box = @get('controller.content')
    promise = AIO.AddonSubscription.provision @get('addonPlan.id'), box.get('id')
    success = (model) =>
      @get('controller.subscriptions').addObject model
    failed = (model) =>
      errors = @get('controller.content.errors') || {}
      errors['base'] = ['Failed to subscribe to the addon']
      @set 'controller.content.errors', errors
    promise.then success, failed

AIO.BoxAddonPlanDeprovisionButton = Em.View.extend
  tagName: "button"
  template: Em.Handlebars.compile("Deprovision")
  classNames: ["btn", "btn-danger"]
  attributeBindings: ['disabled']

  addonSubscription: null
  disabledBinding: 'addonSubscription.isLoading'

  click: ->
    @get('addonSubscription').deprovision()
