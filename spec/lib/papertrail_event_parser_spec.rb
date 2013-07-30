require 'spec_helper'

describe PapertrailEventParser do
  let!(:user_1) { create :user }
  let!(:user_2) { create :user }

  let!(:box_1)  { create :box, owner: user_1 }
  let!(:box_2)  { create :box, owner: user_2 }

  let!(:payload) do
"""
{
  \"events\": [
    {
      \"display_received_at\": \"Jul 29 00:09:07\",
      \"facility\": \"User\",
      \"hostname\": \"apse1\",
      \"id\": 2.9829606901896e+17,
      \"message\": \"[13046557.173862] Task in \/lxc\/#{box_1.container_name} killed as a result of limit of \/lxc\/#{box_1.container_name}\",
      \"program\": \"kernel\",
      \"received_at\": \"2013-07-29T00:09:07Z\",
      \"severity\": \"Info\",
      \"source_id\": 3416271,
      \"source_ip\": \"54.251.42.128\",
      \"source_name\": \"apse1\"
    },

    {
      \"display_received_at\": \"Jul 29 00:09:07\",
      \"facility\": \"User\",
      \"hostname\": \"apse1\",
      \"id\": 2.9829607084349e+17,
      \"message\": \"[13046557.249651] Task in \/lxc\/#{box_1.container_name} killed as a result of limit of \/lxc\/#{box_1.container_name}\",
      \"program\": \"kernel\",
      \"received_at\": \"2013-07-29T00:09:07Z\",
      \"severity\": \"Info\",
      \"source_id\": 3416271,
      \"source_ip\": \"54.251.42.128\",
      \"source_name\": \"apse1\"
    },

    {
      \"display_received_at\": \"Jul 29 02:17:26\",
      \"facility\": \"User\",
      \"hostname\": \"apse1\",
      \"id\": 2.9832835956876e+17,
      \"message\": \"[13054256.045137] Task in \/lxc\/#{box_2.container_name} killed as a result of limit of \/lxc\/#{box_2.container_name}\",
      \"program\": \"kernel\",
      \"received_at\": \"2013-07-29T02:17:26Z\",
      \"severity\": \"Info\",
      \"source_id\": 3416271,
      \"source_ip\": \"54.251.42.128\",
      \"source_name\": \"apse1\"
    },

    {
      \"display_received_at\": \"Jul 29 02:35:31\",
      \"facility\": \"User\",
      \"hostname\": \"apse1\",
      \"id\": 2.9833291050184e+17,
      \"message\": \"[13055341.015822] Task in \/lxc\/#{box_2.container_name} killed as a result of limit of \/lxc\/#{box_2.container_name}\",
      \"program\": \"kernel\",
      \"received_at\": \"2013-07-29T02:35:31Z\",
      \"severity\": \"Info\",
      \"source_id\": 3416271,
      \"source_ip\": \"54.251.42.128\",
      \"source_name\": \"apse1\"
    }

  ],
  \"max_id\": \"298592156099325960\",
  \"min_id\": \"298296069018963971\",
  \"min_time_at\": \"2013-07-29T00:09:07Z\",
  \"reached_record_limit\": true,
  \"saved_search\": {
    \"html_edit_url\": \"https:\/\/papertrailapp.com\/searches\/732743\/edit\",
    \"html_search_url\": \"https:\/\/papertrailapp.com\/searches\/732743\",
    \"id\": 732743,
    \"name\": \"killed as a result of limit of\",
    \"query\": \"killed as a result of limit of\"
  }
}
"""
  end

  describe ".parse!" do
    context "box_1" do
      it "should add box_limit_hit_events to box_1" do
        expect {
          PapertrailEventParser.parse!(payload)
        }.to change(box_1.box_limit_hit_events, :count).by(2)

        limit_hit_events = box_1.box_limit_hit_events.order("id ASC")

        expect(limit_hit_events[0].limit_hit_at.to_i).to eql 1375056547
        expect(limit_hit_events[0].kind).to eql BoxLimitHitEvent::MEMORY
        expect(limit_hit_events[0].logged_event_id).to eql '298296069018960000'

        expect(limit_hit_events[1].limit_hit_at.to_i).to eql 1375056547
        expect(limit_hit_events[1].kind).to eql BoxLimitHitEvent::MEMORY
        expect(limit_hit_events[1].logged_event_id).to eql '298296070843489984'
      end
    end

    context "box_2" do
      it "should add box_limit_hit_events to box_2" do
        expect {
          PapertrailEventParser.parse!(payload)
        }.to change(box_2.box_limit_hit_events, :count).by(2)

        limit_hit_events = box_2.box_limit_hit_events.order("id ASC")

        expect(limit_hit_events[0].limit_hit_at.to_i).to eql 1375064246
        expect(limit_hit_events[0].kind).to eql BoxLimitHitEvent::MEMORY
        expect(limit_hit_events[0].logged_event_id).to eql '298328359568760000'

        expect(limit_hit_events[1].limit_hit_at.to_i).to eql 1375065331
        expect(limit_hit_events[1].kind).to eql BoxLimitHitEvent::MEMORY
        expect(limit_hit_events[1].logged_event_id).to eql '298332910501840000'
      end
    end
  end
end
