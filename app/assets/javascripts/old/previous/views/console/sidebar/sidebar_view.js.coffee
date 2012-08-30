aio.views.console ||= {}
aio.views.console.sidebar ||= {}

class aio.views.console.sidebar.SidebarView extends Backbone.View
  template: JST['previous/templates/console/sidebar/sidebar_view']
  id: 'console-sidebar'

  initialize: ->
    aio.app.boxes.on('reset add remove', this.render, this)
    aio.app.publicKeys.on('reset add remove', this.render, this)

  render: ->
    @$el.html(this.template(boxes: aio.app.boxes.toJSON(), publicKeys: aio.app.publicKeys.toJSON()))
    @$newBoxButton = this.$('#new_box_button')
    @$newBoxButton.attr('disabled', true) if aio.app.boxTemplates.length == 0

    for box in aio.app.boxes.models
      boxView = new aio.views.console.sidebar.BoxView(model: box)
      this.$('.boxes ul').append(boxView.render().$el)

    this

  events:
    'click #new_box_button' : 'didClickNewBoxButton'

  didClickNewBoxButton: (e) ->
    $button = $(e.target)
    window.navigateTo('#boxes/new')

