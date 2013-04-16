#= require jquery
#= require jquery_ujs
#= require bootstrap
#= require underscore
#= require modernizr-html5-2.6.2
#= require json2
#= require_self
#= require licenses
#= require pages/jobs_page

if location.hash == '#aio'
  # show name change notice
  $div = $('<div>').attr('id', 'name-change-notice').addClass('container').html("<p><i class='icon-bullhorn'></i> Action.IO is now Nitrous.IO! <a href='http://blog.nitrous.io/2013/04/16/actionio-is-now-nitrousio.html'>Read more...</a></p>")
  $(body).append($div)
  window.setTimeout(->
    $div.fadeIn()
  , 200)
  $div.click (e) ->
    $div.fadeOut() if e.target.tagName.toLowerCase() == 'p'

$ ->
  $('.alert').addClass 'in'
