class ActiveRecord::Base
  def serialize_as_hash(options={})
    active_model_serializer.new(self, options).as_json
  end

  def serialize_as_json(options={})
    active_model_serializer.new(self, options).to_json
  end
end

class Array
  def serialize_as_hash(options={})
    active_model_serializer.new(self, options).as_json
  end

  def serialize_as_json(options={})
    active_model_serializer.new(self, options).to_json
  end
end

