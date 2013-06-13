class KeyValue < ActiveRecord::Base
  attr_accessible :key, :value

  def value
    JSON.parse("[#{json_value}]")[0]
  end

  def value=(val)
    self.json_value = val.nil? ? nil : val.to_json
  end

  def self.[](k)
    KeyValue.select('json_value').find_by_key(k).try(:value)
  end
end
