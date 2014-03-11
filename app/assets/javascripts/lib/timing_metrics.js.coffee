AIO.TimingMetrics =
  record: (measurement, duration) ->
    jQuery.ajax
      url:        "/timing/#{measurement}"
      dataType:   'json'
      type:       'POST'
      data:       { duration: duration }
