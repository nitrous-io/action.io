class AIO.View extends Backbone.View
  template: -> ''

  render: ->
    @$el.empty().html(this.template())
    this

