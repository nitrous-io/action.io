window.AIO ||= {}

class AIO.HomePage
  constructor: (mixpanelProperties = {}) ->
    mixpanel.track('Viewed Home Page', mixpanelProperties) if mixpanel?
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
