AIO.ManageAuthDialog = Em.Object.extend
  contentBinding: 'AIO.router.ideController.content'
  saving: false
  errorMessage: null

  updateAuth: (cb) ->
    @get('content').updateAuth cb
