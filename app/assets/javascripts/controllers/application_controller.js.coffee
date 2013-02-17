AIO.ApplicationController = Em.Controller.extend
  needs: ['regions', 'boxTemplates']

  initialize: (options={}) ->
    if environment = options.environment
      AIO.set 'environment', environment

    if pusherKey = options.pusherKey
      AIO.get('router.pusherController').initialize pusherKey

