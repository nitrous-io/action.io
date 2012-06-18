class AIO.Box extends AIO.Model
  urlRoot: '/boxes'

  defaults:
    name: null
    region: null

  destroy: (options={}) ->
    $.ajax(_.extend(options, type: 'DELETE', url: this.url()))

AIO.Box.setup('boxes')

