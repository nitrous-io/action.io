require 'spec_helper'

describe DesktopAppsController do
  describe 'routing' do
    specify { expect(get: '/mac').to route_to controller: 'desktop_apps', action: 'index' }
    specify { expect(get: '/desktop').to route_to controller: 'desktop_apps', action: 'index' }
    specify { expect(get: '/windows').to route_to controller: 'desktop_apps', action: 'index' }

    specify { expect(get: '/mac/NitrousDesktop-latest.zip').to route_to controller: 'desktop_apps', action: 'download', platform: 'mac' }
    specify { expect(get: '/windows/NitrousDesktop-Windows-latest.zip').to route_to controller: 'desktop_apps', action: 'download', platform: 'windows' }

    specify { expect(get: '/desktop_apps/mac/appcast.xml').to route_to controller: 'desktop_apps', action: 'appcast', format: 'xml', platform: 'mac' }
    specify { expect(get: '/desktop_apps/mac/release_notes/1.2.3-beta1').to route_to controller: 'desktop_apps', action: 'release_notes', version: '1.2.3-beta1', platform: 'mac' }
    specify { expect(get: '/desktop_apps/windows/appcast.xml').to route_to controller: 'desktop_apps', action: 'appcast', format: 'xml', platform: 'windows' }
    specify { expect(get: '/desktop_apps/windows/release_notes/1.2.3-beta1').to route_to controller: 'desktop_apps', action: 'release_notes', version: '1.2.3-beta1', platform: 'windows' }

    # legacy urls
    specify { expect(get: '/mac/appcast.xml').to route_to controller: 'desktop_apps', action: 'appcast', format: 'xml', platform: 'mac' }
    specify { expect(get: '/mac/release_notes/1.2.3-rc2').to route_to controller: 'desktop_apps', action: 'release_notes', version: '1.2.3-rc2', platform: 'mac' }
  end
end
