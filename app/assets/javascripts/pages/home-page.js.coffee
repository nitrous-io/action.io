window.App ||= {}

class App.HomePage
  constructor: (email, mixpanelProperties = {}) ->
    if mixpanel?
      mixpanel.register(mixpanelProperties)
      mixpanel.identify email if email?.length > 0
      mixpanel.track('Viewed Home Page', mixpanelProperties)
    $('#first-step').focus()

    @stacks = ["Ruby", "Python", "Node.js", "PHP", "Go", "Meteor"]
    @i = 0

    this.changeStackName()
    setInterval(=>
      this.changeStackName()
    , 3000)

    $emailConfirmation = $('#email-confirmation')
    if $emailConfirmation.length > 0
      $('.close-button', $emailConfirmation).click ->
        $emailConfirmation.hide()

    $('form.cta-get-started input').focus(->
      $(this).closest('form').addClass('focused')
    ).blur ->
      $(this).closest('form').removeClass('focused')

    $('form.cta-get-started').submit (event) ->
      event.preventDefault()
      url = 'https://pro.nitrous.io/app/#/signup'
      if email = $(event.target).find("[name='email']").val()
        url += "?email=#{encodeURIComponent(email)}"
      # set href instead of replace to preserve history (navigate instead of redirect)
        window.location.href = url

  changeStackName: ->
    @$stackNameSpan ?= $("#stack-name span")
    @$stackNameSpan.text(@stacks[@i % @stacks.length])
    @i += 1