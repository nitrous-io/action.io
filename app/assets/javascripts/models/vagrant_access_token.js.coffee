AIO.VagrantAccessToken = Em.Object.extend
  access_token: null
  fetching: false

  resourceUrl: '/vagrant/access_token'

  vagrantfile: (->
    if accessToken = @get 'access_token'
      """
      Vagrant.configure("2") do |config|
        config.vm.box = "actionio-dummy"

        config.vm.provider :actionio do |aio|
          aio.access_token = "#{accessToken}"
          aio.region   = "us-west-1"    # refer to the docs for supported regions
          aio.box_name = "my-rails-box" # name of the box to be created in action.io
          aio.stack    = "rails"        # name of the base stack to use
        end
      end
      """
  ).property 'access_token'

  find: ->
    @set 'fetching', true
    $.get(@get 'resourceUrl').done((json) =>
      @set 'access_token', json.access_token
    ).fail(->
      window.alert 'Failed to fetch access token. Please try again later.'
    ).always =>
      @set 'fetching', false

