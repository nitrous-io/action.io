aio.views ||= {}
aio.views.console ||= {}

class aio.views.console.SidebarView extends Backbone.View
  template: JST['console/sidebar']
  id: 'console-sidebar'

  render: ->
    @$el.html(this.template())
    @$newBoxButton = this.$('#new_box_button')
    this

  events:
    'click #new_box_button' : 'didClickNewBoxButton'

  didClickNewBoxButton: (e) ->
    $button = $(e.target)
    window.navigateTo('#new_box')

