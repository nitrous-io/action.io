window.AIO ||= {}

class AIO.TeamPage
  constructor: ->
    $("[rel='tooltip']").tooltip(html: true)
    $('.carousel').carousel(interval: 5000)
