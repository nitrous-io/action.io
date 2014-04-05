require 'spec_helper'

describe HackButtonController do
  specify { expect(get: '/hack_button').to route_to controller: 'hack_button', action: 'index' }
  specify { expect(get: '/embed').to route_to controller: 'hack_button', action: 'embed' }
end
