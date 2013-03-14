AIO.VagrantIndexView = Em.View.extend
  templateName: 'templates/vagrant/index'
  classNames: ['app_page', 'index']
  elementId: 'vagrant_index_view'

  didClickGetAccessToken: ->
    controller = @get 'controller'
    controller.getAccessToken()

