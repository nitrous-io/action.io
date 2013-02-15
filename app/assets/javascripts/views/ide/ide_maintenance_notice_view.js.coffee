AIO.IdeMaintenanceNoticeView = Em.View.extend
  classNames: [ 'modal' ]
  templateName: 'templates/ide/maintenance_notice'
  elementId: 'ide_maintenance_notice_view'
  classNameBindings: [ 'AIO.backendDisabled:visible:hide']
