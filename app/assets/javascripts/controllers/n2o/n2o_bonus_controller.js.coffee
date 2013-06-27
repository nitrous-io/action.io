AIO.N2oBonusController = Em.ObjectController.extend
  content: null
  bonusInfo: null

  reload: ->
    $.ajax(
      type: 'GET'
      dataType: 'json'
      url: '/bonus'
    ).done (json) =>
      if attrs = json.bonus
        @get('content')?.setProperties attrs
