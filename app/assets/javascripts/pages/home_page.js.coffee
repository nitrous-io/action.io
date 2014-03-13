window.AIO ||= {}

class AIO.HomePage
  constructor: (email, mixpanelProperties = {}) ->
    if mixpanel?
      mixpanel.register(mixpanelProperties)
      mixpanel.identify email if email?.length > 0
      mixpanel.track('Viewed Home Page', mixpanelProperties)
    $('#first-step').focus()

    @stacks = ["Ruby", "Python", "Node.js", "PHP", "Go"]
    @i = 0

    this.changeStackName()
    setInterval(=>
      this.changeStackName()
    , 3000)

  changeStackName: ->
    @$stackNameSpan ?= $("#stack-name span")
    @$stackNameSpan.text(@stacks[@i % @stacks.length])
    @i += 1
