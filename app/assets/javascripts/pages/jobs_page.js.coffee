#= require jquery
$ ->
  chooseJob = ->
    if (hash = window.location.hash) != ''
      $("#{hash} .expandable").click()

  $(window).on 'load', -> chooseJob()
  $(window).on 'hashchange', -> chooseJob()

$('.expandable').click ->
  $(this).next().toggleClass 'expanded'
  $(this).find('a.more-details i').toggleClass('icon-minus', 'icon-plus')
