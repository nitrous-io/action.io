require 'spec_helper'

describe PromosController do
  specify { expect(get: '/promo/buylah').to route_to controller: 'promos', action: 'index', code: 'buylah' }
end
