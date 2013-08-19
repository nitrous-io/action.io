#= require jquery
#= require jquery_ujs
#= require bootstrap
#= require underscore
#= require modernizr-html5-2.6.2
#= require json2
#= require_self
#= require license
#= require placeholder_polyfill.jquery
#= require pages/home_page

if location.hash == '#aio'
  # show name change notice
  $div = $('<div>').attr('id', 'name-change-notice').addClass('container').html("<p><i class='icon-bullhorn'></i> Action.IO is now Nitrous.IO! <a href='http://blog.nitrous.io/2013/04/16/actionio-is-now-nitrousio.html'>Read more...</a></p>")
  $('body').append($div)
  window.setTimeout(->
    $div.fadeIn()
  , 200)
  $div.click (e) ->
    $div.fadeOut() if e.target.tagName.toLowerCase() == 'p'

if window.chrome?.app? && window.chrome?.webstore?
  unless window.chrome.app.isInstalled
    $div = $('<div>').attr('id', 'install-chrome-app').html("<p>Install Our Chrome App</p>")
    $('body').prepend($div)
    $div.click ->
      url = $('link[rel=chrome-webstore-item]').attr('href')
      window.chrome.webstore.install url, (o) ->
        $('#install-chrome-app').slideUp()
        window.AIO?.get?('router.n2oBonusController')?.notifyChromeAppInstallation()

$ ->
  window.setTimeout(->
    $('.alert')?.addClass 'in'
  , 500)

  $(window).on 'message', (event) ->
    if event.originalEvent.data == "chromeWebView"
      window.AIO?.set? 'isChromeWebView', true
      $('#page-header, #header-bottom, #install-chrome-app').hide()
