AIO.HeaderView = Em.View.extend
  templateName: 'templates/partials/header'
  elementId: 'header_view'

  noMenu: false

  hideHeader: (->
    AIO.get('isChromeWebView')
  ).property 'AIO.isChromeWebView'
