#= require jquery

$('.expandable').click ->
  $(this).next().toggleClass 'expanded'
  $(this).find('a.more-details i').toggleClass('icon-minus', 'icon-plus')
