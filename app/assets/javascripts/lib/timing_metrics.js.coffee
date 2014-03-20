AIO.TimingMetrics =
  record: (metric, duration, region, host) ->
    jQuery.ajax
      url:        "/timing/#{metric}"
      dataType:   'json'
      type:       'POST'
      data:       { duration: duration, region: region, host: host }
