require 'spec_helper'

describe MacController do
  describe 'routing' do
    specify { expect(get: '/mac').to route_to controller: 'mac', action: 'index' }
    specify { expect(get: '/mac/appcast.xml').to route_to controller: 'mac', action: 'appcast', format: 'xml' }
    specify { expect(get: '/mac/release_notes/1.2.3-rc2').to route_to controller: 'mac', action: 'release_notes', version: '1.2.3-rc2' }
    specify { expect(get: '/mac/NitrousDesktop-latest.zip').to route_to controller: 'mac', action: 'download' }
  end
end
