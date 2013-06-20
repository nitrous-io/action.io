require 'spec_helper'

describe WebAppController do
  let(:user) { create :user }

  describe 'GET index' do
    let!(:another_user) { create :user }
    let!(:region1) { create :region, enabled: true }
    let!(:region2) { create :region, enabled: true }
    let!(:region3) { create :region }
    let!(:box_template1) { create :box_template }
    let!(:box_template2) { create :box_template }
    let!(:box1) { create :box, box_template: box_template1, users: [user], region: region1 }
    let!(:box2) { create :box, box_template: box_template1, users: [user, another_user], region: region1 }
    let!(:box3) { create :box, box_template: box_template2, users: [another_user], region: region1 }
    let!(:box4) { create :box, box_template: box_template1, users: [user], region: region1 }
    let!(:box5) { create :box, box_template: box_template1, users: [user], region: region1 }

    before do
      KeyValue.create(key: N2oFill::N2O_INVITING_WITHIN_LIMITS_BONUS, value: 10)
      KeyValue.create(key: N2oFill::N2O_OAUTH_ACTION_BONUS, value: 5)
    end

    def do_request
      get :index
    end

    context 'when logged in' do
      before do
        sign_in user
        Timecop.freeze do
          box4.update_attribute :terminated_at, 1.day.ago + 1.second
          box5.update_attribute :terminated_at, 1.day.ago
          do_request
        end
      end

      it { should render_template 'index' }
      it { should respond_with :success }

      it 'ivars for the view' do
        expect(assigns :user_serializer).to be_kind_of UserSerializer
        expect(assigns :boxes).to   eq [box1, box2, box4]
        expect(assigns :regions).to eq [region1, region2]
        expect(assigns :box_templates).to eq [box_template1, box_template2]
        expect(assigns :n2o_128mb_memory).to  eq KeyValue[N2oAllocation::N2O_128MB_MEMORY]
        expect(assigns :n2o_250mb_storage).to eq KeyValue[N2oAllocation::N2O_250MB_STORAGE]
        expect(assigns :bonus).to eq user.bonus
        expect(assigns(:available_bonuses).symbolize_keys).to eq Bonus.available_bonuses
      end
    end

    it_behaves_like 'an action that requires sign in'
  end
end
