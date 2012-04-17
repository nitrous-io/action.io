class aio.models.Box extends Backbone.Model
  region: ->
    aio.app.regions.get(this.get('region_id'))

  boxTemplate: ->
    aio.app.boxTemplates.get(this.get('box_template_id'))

  start: (options={}) ->
    this.makeBoxControlRequest 'start', options

  suspend: (options={}) ->
    this.makeBoxControlRequest 'suspend', options

  resume: (options={}) ->
    this.makeBoxControlRequest 'resume', options

  stop: (options={}) ->
    this.makeBoxControlRequest 'stop', options

  makeBoxControlRequest: (action, options={}) ->
    $.ajax
      type: 'PUT'
      url: "#{this.url()}/#{action}"
      success: (data) =>
        this.set(data)
        options.success(data) if options.success
      error: (data) =>
        options.error(data) if options.error
      complete: =>
        options.complete() if options.complete

class aio.collections.Boxes extends Backbone.Collection
  model: aio.models.Box
  url: '/boxes'

