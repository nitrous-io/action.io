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
          aio.stack    = "rails"        # name of the base stack to use
          aio.ssh_private_key_path = "~/.ssh/id_rsa" # path to your ssh private key
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

