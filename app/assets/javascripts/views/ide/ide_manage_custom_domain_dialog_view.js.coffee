AIO.IdeManageCustomDomainDialogView = AIO.IdeModalDialogView.extend
  templateName: 'templates/ide/manage_custom_domain_dialog'
  elementId: 'ide_manage_custom_domain_dialog_view'
  contentBinding: 'controller.manageCustomDomainDialog' # controller = ideCustomDomainController

  didClickUpdate: ->
    @get('controller').updateCustomDomain()
