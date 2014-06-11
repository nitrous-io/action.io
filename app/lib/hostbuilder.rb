module Hostbuilder
  HOSTBUILDER_URI = ENV['HOSTBUILDER_URI']

  class HostbuilderError < RuntimeError; end

  def self.by_name(name)
    "Hostbuilder::#{name.classify}".constantize
  rescue NameError
    nil
  end
end
