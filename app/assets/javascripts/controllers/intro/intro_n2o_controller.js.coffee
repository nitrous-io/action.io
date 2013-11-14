AIO.IntroN2oController = Em.ObjectController.extend
  content: null
  # bonusInfoBinding: Em.Binding.oneWay 'AIO.router.n2oBonusController.bonusInfo'

  reload: ->
    $.ajax(
      type: 'GET'
      dataType: 'json'
      url: '/bonus'
    ).done (json) =>
      if attrs = json.bonus
        @get('content')?.setProperties attrs

  reset: ->
    @set 'content', null
