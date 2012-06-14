require 'spec_helper'

describe GeocodeInviteJob do
  describe '#perform' do
    let!(:invite) { create :invite, ip: '202.157.130.10' }
    let!(:job)    { GeocodeInviteJob.new(invite.id) }

    # Geocoder.search returns an array
    before { Geocoder.stub!(:search).with(invite.ip) { [double(:result, data: { "city" => "Singapore",
                                                                                "region_code" => "",
                                                                                "region_name" => "",
                                                                                "metrocode" => "",
                                                                                "zipcode" => "",
                                                                                "longitude" => "103.856",
                                                                                "latitude" => "1.2931",
                                                                                "country_code" => "SG",
                                                                                "ip" => "202.157.130.10",
                                                                                "country_name" => "Singapore"
                                                                              })] } }
    it 'uses the Geocoder API to geocode the ip' do
      Geocoder.should_receive(:search).with('202.157.130.10')
      job.perform

      invite.reload.city.should == 'Singapore'
      invite.country.should == 'Singapore'
      invite.latitude.should == 1.2931
      invite.longitude.should == 103.856
      invite.country_code.should == 'SG'
    end
  end
end
