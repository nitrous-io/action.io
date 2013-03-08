AIO.BoxesNewController = Em.ObjectController.extend
  needs: ['boxesIndex', 'boxTemplates', 'regions']
  boxes: null
  boxTemplates: null
  regions: null
  boxesBinding: 'controllers.boxesIndex'
  boxTemplatesBinding: 'controllers.boxTemplates'
  regionsBinding: 'controllers.regions'

  save: ->
    record = @get 'content'
    record.save =>
      @get('boxes').addObject record
      @transitionToRoute 'boxes.provisioning', record

  cancel: ->
    @set 'content', null
    this.transitionToRoute 'boxes.index'
