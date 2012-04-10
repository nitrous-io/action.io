aio.views.console ||= {}

class aio.views.console.SidebarView extends Backbone.View
  template: JST['console/sidebar']
  id: 'console-sidebar'

  initialize: ->
    aio.app.boxes.on('reset add remove', this.render, this)

  render: ->
    @$el.html(this.template(box_count: aio.app.boxes.length))
    @$newBoxButton = this.$('#new_box_button')
    @$newBoxButton.attr('disabled', true) if aio.app.boxTemplates.length == 0
    for box in aio.app.boxes.models
      boxView = new aio.views.console.SidebarBoxView(model: box)
      this.$('> div > ul').append(boxView.render().$el)
    this

  events:
    'click #new_box_button' : 'didClickNewBoxButton'

  didClickNewBoxButton: (e) ->
    $button = $(e.target)
    window.navigateTo('#boxes/new')

