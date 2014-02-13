AIO.IdeCustomDomainController = Em.Controller.extend
  manageCustomDomainDialog: null

  reset: ->
    @set 'manageCustomDomainDialog', null

  showCustomDomainDialog: ->
    if box = AIO.get 'router.ideController.content'
      @set 'manageCustomDomainDialog', AIO.ManageCustomDomainDialog.create(box: box)

  updateCustomDomain: ->
    if box = AIO.get 'router.ideController.content'
      box.updateCustomDomain (err) =>
	unless err
	  @set 'manageCustomDomainDialog', null
