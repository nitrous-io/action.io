AIO.HeaderView = Em.View.extend
  templateName: 'templates/partials/header'
  elementId: 'header_view'

  hideHeaderBinding: Em.Binding.oneWay 'AIO.isChromeWebView'

  noMenu: false
