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
      # remove all expanded instances
      $('ul#jobs>li>.details').removeClass 'expanded'
      $this.next().addClass 'expanded' unless $this.next().hasClass 'expanded'
      $('a.more-details i', $this).toggleClass('icon-minus', 'icon-plus')
