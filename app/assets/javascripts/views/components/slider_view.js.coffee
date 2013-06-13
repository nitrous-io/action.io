AIO.SliderView = Em.View.extend
  classNames: ['slider_view']
  templateName: 'templates/components/slider'
  value: null
  min: 0
  max: 100
  step: 10
  unit: null

  init: ->
    @_super()
    unless value = @get 'value'
      @set 'value', @get('min')

  valueLabel: (->
    "#{@get 'value'}#{@get('unit') || ''}"
  ).property 'value'

  mouseDown: (event) ->
    event.preventDefault()
    this.updateBar event

    $body = $('body')

    $body.on 'mousemove.sliderView', (event) =>
      this.updateBar event

    eventsOff = ->
      $body.off 'mousemove.sliderView'
      $body.off 'mouseup.sliderView'
      $body.off 'mouseleave.sliderView'

    $body.on 'mouseup.sliderView', eventsOff
    $body.on 'mouseleave.sliderView', eventsOff

  updateValueByFraction: (fraction) ->
    min = @get 'min'
    max = @get 'max'
    step = @get 'step'
    maxMinusMin = max - min

    valueMinusMin = Math.round(fraction * maxMinusMin / step) * step
    value = valueMinusMin + min
    @set 'value', value
    value

  updateBar: (event) ->
    $el = @$()
    width = $el.width()
    mouseX = Math.max(0, event.pageX - $el.offset().left)
    fraction = Math.min(1, (mouseX / width))

    value = this.updateValueByFraction fraction
    max = @get 'max'
    min = @get 'min'
    percentage = (value - min) / (max - min) * 100
    @$('.bar').css('width', "#{percentage}%")
