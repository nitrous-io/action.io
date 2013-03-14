AIO.VagrantAccessToken = Em.Object.extend
  access_token: null
  fetching: false

  resourceUrl: '/vagrant/access_token'

  vagrantfile: (->
    if accessToken = @get 'access_token'
      """
      Vagrant::Config.run do |c|
        c.actionio.access_token = '#{accessToken}'
        c.actionio.region   = 'us-west-1'    # refer to the docs for supported regions
        c.actionio.box_name = 'my-rails-box' # name of the box to be created in action.io
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

