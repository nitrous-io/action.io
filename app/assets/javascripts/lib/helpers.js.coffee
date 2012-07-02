AIO.showAlertDialog = (title, message) ->
  $alertDialog = $('#alert_dialog')
  if $alertDialog.length > 0
    $('.title', $alertDialog).text(title)
    $('.message', $alertDialog).text(message)
    $alertDialog.modal('show')

