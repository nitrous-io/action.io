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
    let!(:key1) { create :public_key, user: user }
    let!(:key2) { create :public_key, user: another_user }
    let!(:key3) { create :public_key, user: user }
    let!(:plan1) { create :plan }
    let!(:plan2) { create :plan }


    before do
      KeyValue.create key: N2oAllocation::N2O_128MB_MEMORY,  value: 40
      KeyValue.create key: N2oAllocation::N2O_250MB_STORAGE, value: 10
      KeyValue.create key: N2oFill::N2O_INVITING_WITHIN_LIMITS_BONUS, value: 10
      KeyValue.create key: N2oFill::N2O_OAUTH_ACTION_BONUS, value: 5

      KeyValue.create key: Box::N2O_MAX_MEMORY_MB,  value: 2048
      KeyValue.create key: Box::N2O_MAX_STORAGE_MB, value: 10000
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

      it 'sets ivars for the view' do
        expect(assigns(:boxes        )).to match_array([box1, box2])
        expect(assigns(:public_keys  )).to match_array([key1, key3])
        expect(assigns(:regions      )).to match_array([region1, region2])
        expect(assigns(:box_templates)).to match_array([box_template1, box_template2])
        expect(assigns(:plans)).to match_array([plan1, plan2])
        expect(assigns :n2o_128mb_memory).to  eq 40
        expect(assigns :n2o_250mb_storage).to eq 10
        expect(assigns :bonus).to eq user.bonus
        expect(assigns(:bonus_info).symbolize_keys).to eq Bonus.bonus_info
        expect(assigns(:coupon_code)).to be_nil
        expect(assigns(:max_memory_in_gb)).to eql 2
        expect(assigns(:max_storage_in_gb)).to eql 10
      end

      context 'when coupon_code cookie is present in the request' do
        before { request.cookies['coupon_code'] = 'much-savings' }

        it 'should set the coupon_code ivar to its value' do
          do_request
          expect(assigns(:coupon_code)).to eq('much-savings')
        end

        it 'should delete the cookie' do
          do_request
          expect(response.cookies['coupon_code']).to be_nil
        end
      end
    end

    it_behaves_like 'an action that requires sign in'
  end
end
