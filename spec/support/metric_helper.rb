RSpec.configure do |config|
  config.before :each do
    METRICS.stub(:send_to_socket)
  end
end
