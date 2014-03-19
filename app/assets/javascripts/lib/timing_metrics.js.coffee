AIO.TimingMetrics =
  record: (region, measurement, duration) ->
    jQuery.ajax
      url:        "/timing/#{measurement}"
      dataType:   'json'
      type:       'POST'
      data:       { duration: duration, region: region }
