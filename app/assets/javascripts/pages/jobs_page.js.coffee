#= require jquery
window.AIO ||= {}

AIO.JobsPage =
  initialize: ->
    chooseJob = ->
      if (hash = window.location.hash) != ''
        $expandable = $ "#{hash} .expandable"
        $expandable.next().addClass('expanded')
        $('a.more-details i', $expandable).addClass('icon-minus')

    $(window).on 'load', chooseJob
    $(window).on 'hashchange', chooseJob
    $('#position_links a').on 'click', chooseJob

    $('.expandable').click ->
      $this = $(this)
      $this.next().toggleClass 'expanded'
      $('a.more-details i', $this).toggleClass('icon-minus', 'icon-plus')
