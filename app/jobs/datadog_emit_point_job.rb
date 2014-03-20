class DatadogEmitPointJob < Job
  attr_accessor :metric, :value, :options

  def initialize(metric, value, options={})
    self.metric  = metric
    self.value   = value
    self.options = options
  end

  def perform
    Datadog.emit_point(metric, value, options)
  end

  def self.submit_job(metric, value, options = {})
    Delayed::Job.enqueue(self.new(metric, value, options))
  end
end
