AIO.IdeAutopartsController = Em.Controller.extend
  manageAutopartsDialog: null

  reset: ->
    @set 'manageAutopartsDialog', null

  showManageAutopartsDialog: ->
    if box = AIO.get 'router.ideController.content'
      @set 'manageAutopartsDialog', AIO.ManageAutopartsDialog.create box: box
