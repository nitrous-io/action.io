#= require jquery
#= require jquery_ujs
#= require bootstrap
#= require underscore
#= require modernizr-html5-2.6.2
#= require json2
#= require_self
#= require license
#= require placeholder_polyfill.jquery
#= require mailcheck
#= require pages/home_page

if location.hash == '#aio'
  # show name change notice
  $div = $('<div>').attr('id', 'name-change-notice').addClass('top-announcement container').html("<p><i class='icon-bullhorn'></i> Action.IO is now Nitrous.IO! <a href='http://blog.nitrous.io/2013/04/16/actionio-is-now-nitrousio.html'>Read more...</a></p>")
  $('body').append($div)
  window.setTimeout(->
    $div.fadeIn()
  , 200)
  $div.click (e) ->
    $div.fadeOut() if e.target.tagName.toLowerCase() == 'p'

$ ->
  window.setTimeout(->
    $('.alert')?.addClass 'in'
  , 500)

  $(window).on 'message', (event) ->
    if event.originalEvent.data == "chromeWebView"
      window.AIO?.set? 'isChromeWebView', true
      $('#page-header, #header-bottom').hide()

  $('body').on 'blur', '.mailcheck', (event) ->
    _removeSuggest = =>
      $(this).nextAll('#mail-suggest').remove()

    _removeSuggest()

    $(this).mailcheck
      suggested: ((element, suggestion) ->

        suggestField = $('<div id="mail-suggest"></div>').hide()
        suggestField.html "Did you mean <a>#{suggestion.full}</a>?"

        suggestField.on 'click', (event) ->
          element.val suggestion.full
          _removeSuggest()
          event.preventDefault()

        # need this hack to align suggest block
        # in invites page
        button = element.next('button')
        if button.length
          button.after suggestField
        else
          element.after suggestField

        suggestField.slideDown('fast')
        mixpanel.track('Showed E-Mail Suggestion') if mixpanel?
      )
